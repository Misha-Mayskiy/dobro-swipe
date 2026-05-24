import os
import shutil
import uuid
import json
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_
import redis.asyncio as redis
from app.api import deps
from app.core.config import settings
from app.db.session import get_db
from app.models.models import Task, TaskAssignment, User
from app.schemas.schemas import TaskCreate, TaskResponse, TaskAssignmentResponse, ReportSubmit, ReportReview

router = APIRouter()
redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)

@router.post("/", response_model=TaskResponse)
async def create_task(
    task_in: TaskCreate, 
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(deps.get_current_foundation)
):
    db_task = Task(
        foundation_id=current_user.id,
        title=task_in.title,
        description=task_in.description,
        skills_required=task_in.skills_required,
        duration_minutes=task_in.duration_minutes,
        karma_reward=task_in.karma_reward,
        city=task_in.city,
        latitude=task_in.latitude,
        longitude=task_in.longitude,
        is_physical=task_in.is_physical,
        expires_at=task_in.expires_at
    )
    db.add(db_task)
    await db.commit()
    await db.refresh(db_task)
    return db_task

@router.get("/foundation/dashboard")
async def get_foundation_dashboard(
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(deps.get_current_foundation)
):
    # Fetch tasks created by this foundation
    result = await db.execute(select(Task).filter(Task.foundation_id == current_user.id))
    tasks = result.scalars().all()
    
    # We will return the raw dict for simplicity in MVP
    response_data = []
    for t in tasks:
        # Get assignments for this task
        assign_result = await db.execute(select(TaskAssignment).filter(TaskAssignment.task_id == t.id))
        assignments = assign_result.scalars().all()
        
        response_data.append({
            "id": t.id,
            "title": t.title,
            "status": t.status,
            "assignments": [{"id": a.id, "status": a.status, "volunteer_id": a.volunteer_id, "result_text": a.result_text} for a in assignments]
        })
    return response_data

@router.get("/feed", response_model=List[TaskResponse])
async def get_task_feed(
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(deps.get_current_volunteer)
):
    # Get hidden tasks from Redis (swiped left)
    hidden_tasks_key = f"hidden_tasks:{current_user.id}"
    hidden_task_ids = await redis_client.smembers(hidden_tasks_key)
    hidden_ids = [int(tid) for tid in hidden_task_ids] if hidden_task_ids else []

    # Get active tasks
    query = select(Task).filter(Task.status == "active")
    if hidden_ids:
        query = query.filter(Task.id.not_in(hidden_ids))
    
    # Filter out tasks created by the user (if any, though user is volunteer)
    query = query.filter(Task.foundation_id != current_user.id)
    
    # Simple matching: Same city
    if current_user.city:
        query = query.filter(or_(Task.city == current_user.city, Task.city == None))
        
    result = await db.execute(query)
    tasks = result.scalars().all()
    
    # TODO: Advanced sorting by skills and distance
    return tasks

@router.post("/{task_id}/swipe_left")
async def swipe_left(
    task_id: int, 
    current_user: User = Depends(deps.get_current_volunteer)
):
    hidden_tasks_key = f"hidden_tasks:{current_user.id}"
    await redis_client.sadd(hidden_tasks_key, task_id)
    await redis_client.expire(hidden_tasks_key, 86400) # 24 hours TTL
    return {"status": "hidden"}

@router.post("/{task_id}/swipe_right", response_model=TaskAssignmentResponse)
async def swipe_right(
    task_id: int, 
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(deps.get_current_volunteer)
):
    # Check if user already has an active task
    active_assignment = await db.execute(
        select(TaskAssignment).filter(
            TaskAssignment.volunteer_id == current_user.id,
            TaskAssignment.status == "in_progress"
        )
    )
    if active_assignment.scalars().first():
        raise HTTPException(status_code=400, detail="You already have a task in progress.")

    # Check if task is active
    task_result = await db.execute(select(Task).filter(Task.id == task_id))
    task = task_result.scalars().first()
    if not task or task.status != "active":
        raise HTTPException(status_code=400, detail="Task not available.")

    # Create assignment
    assignment = TaskAssignment(
        task_id=task.id,
        volunteer_id=current_user.id,
        status="in_progress"
    )
    db.add(assignment)
    await db.commit()
    await db.refresh(assignment)
    return assignment

@router.post("/assignments/{assignment_id}/submit")
async def submit_report(
    assignment_id: int, 
    result_text: str = Form(None),
    image: UploadFile = File(None),
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(deps.get_current_volunteer)
):
    result = await db.execute(select(TaskAssignment).filter(TaskAssignment.id == assignment_id))
    assignment = result.scalars().first()
    
    if not assignment or assignment.volunteer_id != current_user.id:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    if assignment.status != "in_progress":
        raise HTTPException(status_code=400, detail="Assignment is not in progress")

    final_result_text = result_text or ""
    
    if image:
        # Save image locally
        filename = f"{uuid.uuid4()}_{image.filename}"
        file_path = os.path.join("uploads", filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        
        # Append image link to result text
        image_url = f"http://localhost:8000/uploads/{filename}"
        final_result_text += f"\n[Image: {image_url}]"

    assignment.status = "under_review"
    assignment.result_text = final_result_text.strip()
    assignment.submitted_at = datetime.utcnow()
    
    await db.commit()
    return {"status": "submitted"}

@router.post("/assignments/{assignment_id}/review")
async def review_report(
    assignment_id: int, 
    review: ReportReview, 
    db: AsyncSession = Depends(get_db), 
    current_user: User = Depends(deps.get_current_foundation)
):
    result = await db.execute(select(TaskAssignment).join(Task).filter(TaskAssignment.id == assignment_id))
    assignment = result.scalars().first()
    
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    task_result = await db.execute(select(Task).filter(Task.id == assignment.task_id))
    task = task_result.scalars().first()

    if task.foundation_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to review this task")

    if assignment.status != "under_review":
        raise HTTPException(status_code=400, detail="Assignment is not under review")

    if review.is_approved:
        assignment.status = "completed"
        task.status = "completed"
        
        # Reward karma
        vol_result = await db.execute(select(User).filter(User.id == assignment.volunteer_id))
        volunteer = vol_result.scalars().first()
        volunteer.karma_balance += task.karma_reward
        # Simple level calculation logic
        volunteer.level = (volunteer.karma_balance // 100) + 1
        
    else:
        assignment.status = "rejected"
        assignment.foundation_comment = review.foundation_comment
        # Return task to pool
        task.status = "active"
        
    await db.commit()
    return {"status": "reviewed"}
