from typing import Any, List
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models import User, Household, user_households, HouseholdInvitation
from app.schemas import (
    Household as HouseholdSchema,
    HouseholdCreate,
    HouseholdUpdate,
    HouseholdInvitation as HouseholdInvitationSchema,
    InvitationCreate,
)

router = APIRouter()


def user_in_household(user: User, household_id: int) -> bool:
    """Check if user is member of household"""
    return any(h.id == household_id for h in user.households)


def is_household_admin(db: Session, user_id: int, household_id: int) -> bool:
    """Check if user is admin of household"""
    user_role = db.execute(
        text(
            "SELECT role FROM user_households WHERE user_id = :user_id AND household_id = :household_id"
        ),
        {"user_id": user_id, "household_id": household_id},
    ).fetchone()
    return user_role and user_role[0] == "admin"


@router.post("", response_model=HouseholdSchema)
def create_household(
    household_in: HouseholdCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Create new household and add current user as admin"""
    db_household = Household(name=household_in.name)
    db.add(db_household)
    db.commit()
    db.refresh(db_household)

    # Add current user as admin of the household
    stmt = user_households.insert().values(
        user_id=current_user.id, household_id=db_household.id, role="admin"
    )
    db.execute(stmt)
    db.commit()

    # Get members with roles
    members_with_roles = db_household.get_members_with_roles(db)

    # Return household with members including roles
    return {
        "id": db_household.id,
        "name": db_household.name,
        "created_at": db_household.created_at,
        "members": members_with_roles,
    }


@router.get("/{household_id}", response_model=HouseholdSchema)
def get_household(
    household_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Get household by ID with members"""
    household = db.query(Household).filter(Household.id == household_id).first()
    if not household:
        raise HTTPException(status_code=404, detail="Household not found")

    if not user_in_household(current_user, household_id):
        raise HTTPException(
            status_code=403, detail="Not authorized to access this household"
        )

    # Get members with roles
    members_with_roles = household.get_members_with_roles(db)

    return {
        "id": household.id,
        "name": household.name,
        "created_at": household.created_at,
        "members": members_with_roles,
    }


@router.put("/{household_id}", response_model=HouseholdSchema)
def update_household(
    household_id: int,
    household_in: HouseholdUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Update household (admin only)"""
    household = db.query(Household).filter(Household.id == household_id).first()
    if not household:
        raise HTTPException(status_code=404, detail="Household not found")

    if not is_household_admin(db, current_user.id, household_id):
        raise HTTPException(status_code=403, detail="Admin access required")

    for key, value in household_in.dict(exclude_unset=True).items():
        setattr(household, key, value)

    db.commit()
    db.refresh(household)

    # Get members with roles for response
    members_with_roles = household.get_members_with_roles(db)

    return {
        "id": household.id,
        "name": household.name,
        "created_at": household.created_at,
        "members": members_with_roles,
    }


@router.delete("/{household_id}/leave")
def leave_household(
    household_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Leave household"""
    if not user_in_household(current_user, household_id):
        raise HTTPException(status_code=404, detail="Not a member of this household")

    # Remove user from household
    stmt = user_households.delete().where(
        user_households.c.user_id == current_user.id,
        user_households.c.household_id == household_id,
    )
    db.execute(stmt)
    db.commit()

    return {"message": "Successfully left household"}


@router.get("", response_model=List[HouseholdSchema])
def get_user_households(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Get all households user belongs to"""
    households = []

    for household in current_user.households:
        # Get members with roles for each household
        members_with_roles = household.get_members_with_roles(db)

        # Create household dict with members including roles
        household_dict = {
            "id": household.id,
            "name": household.name,
            "created_at": household.created_at,
            "members": members_with_roles,
        }
        households.append(household_dict)

    return households


# NEW INVITATION ENDPOINTS


@router.post("/{household_id}/invite")
def invite_to_household(
    household_id: int,
    invitation_data: InvitationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Send invitation to join household (admin only)"""
    # Check if household exists
    household = db.query(Household).filter(Household.id == household_id).first()
    if not household:
        raise HTTPException(status_code=404, detail="Household not found")

    # Check if user is admin of this household
    if not is_household_admin(db, current_user.id, household_id):
        raise HTTPException(status_code=403, detail="Admin access required")

    # Check if invited user exists
    invited_user = db.query(User).filter(User.email == invitation_data.email).first()
    if not invited_user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if user is already in household
    if user_in_household(invited_user, household_id):
        raise HTTPException(status_code=400, detail="User already in household")

    # Check if invitation already exists and is pending
    existing_invite = (
        db.query(HouseholdInvitation)
        .filter(
            HouseholdInvitation.household_id == household_id,
            HouseholdInvitation.invited_user_id == invited_user.id,
            HouseholdInvitation.status == "pending",
        )
        .first()
    )

    if existing_invite:
        raise HTTPException(status_code=400, detail="Invitation already sent")

    # Create invitation
    invitation = HouseholdInvitation(
        household_id=household_id,
        invited_by_id=current_user.id,
        invited_user_id=invited_user.id,
        status="pending",
        created_at=datetime.utcnow(),
    )
    db.add(invitation)
    db.commit()

    return {"message": f"Invitation sent to {invitation_data.email}"}


@router.get("/invitations/received", response_model=List[HouseholdInvitationSchema])
def get_received_invitations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Get all pending invitations for current user"""
    invitations = (
        db.query(HouseholdInvitation)
        .filter(
            HouseholdInvitation.invited_user_id == current_user.id,
            HouseholdInvitation.status == "pending",
        )
        .all()
    )

    return invitations


@router.get("/invitations/sent", response_model=List[HouseholdInvitationSchema])
def get_sent_invitations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Get all invitations sent by current user"""
    invitations = (
        db.query(HouseholdInvitation)
        .filter(HouseholdInvitation.invited_by_id == current_user.id)
        .all()
    )

    return invitations


@router.post("/invitations/{invitation_id}/accept")
def accept_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Accept household invitation"""
    invitation = (
        db.query(HouseholdInvitation)
        .filter(HouseholdInvitation.id == invitation_id)
        .first()
    )

    if not invitation:
        raise HTTPException(status_code=404, detail="Invitation not found")

    if invitation.invited_user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your invitation")

    if invitation.status != "pending":
        raise HTTPException(status_code=400, detail="Invitation already processed")

    # Check if user is already in household (safety check)
    if user_in_household(current_user, invitation.household_id):
        raise HTTPException(status_code=400, detail="Already member of this household")

    # Add user to household
    stmt = user_households.insert().values(
        user_id=current_user.id, household_id=invitation.household_id, role="member"
    )
    db.execute(stmt)

    # Update invitation status
    invitation.status = "accepted"
    invitation.responded_at = datetime.utcnow()

    db.commit()

    return {"message": "Invitation accepted successfully"}


@router.post("/invitations/{invitation_id}/reject")
def reject_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Reject household invitation"""
    invitation = (
        db.query(HouseholdInvitation)
        .filter(HouseholdInvitation.id == invitation_id)
        .first()
    )

    if not invitation:
        raise HTTPException(status_code=404, detail="Invitation not found")

    if invitation.invited_user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your invitation")

    if invitation.status != "pending":
        raise HTTPException(status_code=400, detail="Invitation already processed")

    # Update invitation status
    invitation.status = "rejected"
    invitation.responded_at = datetime.utcnow()

    db.commit()

    return {"message": "Invitation rejected"}


@router.delete("/invitations/{invitation_id}/cancel")
def cancel_invitation(
    invitation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Cancel sent invitation (admin only)"""
    invitation = (
        db.query(HouseholdInvitation)
        .filter(HouseholdInvitation.id == invitation_id)
        .first()
    )

    if not invitation:
        raise HTTPException(status_code=404, detail="Invitation not found")

    # Check if current user is admin of the household
    if not is_household_admin(db, current_user.id, invitation.household_id):
        raise HTTPException(status_code=403, detail="Admin access required")

    if invitation.status != "pending":
        raise HTTPException(
            status_code=400, detail="Can only cancel pending invitations"
        )

    # Update invitation status
    invitation.status = "cancelled"
    invitation.responded_at = datetime.utcnow()

    db.commit()

    return {"message": "Invitation cancelled"}


@router.delete("/{household_id}/members/{user_id}")
def remove_member(
    household_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Any:
    """Remove member from household (admin only)"""
    # Check if current user is admin
    if not is_household_admin(db, current_user.id, household_id):
        raise HTTPException(status_code=403, detail="Admin access required")

    # Check if target user is in household
    target_role = db.execute(
        text(
            "SELECT role FROM user_households WHERE user_id = :user_id AND household_id = :household_id"
        ),
        {"user_id": user_id, "household_id": household_id},
    ).fetchone()

    if not target_role:
        raise HTTPException(status_code=404, detail="User not in household")

    # Don't allow removing admins
    if target_role[0] == "admin":
        raise HTTPException(status_code=400, detail="Cannot remove admin")

    # Remove user from household
    stmt = user_households.delete().where(
        user_households.c.user_id == user_id,
        user_households.c.household_id == household_id,
    )
    db.execute(stmt)
    db.commit()

    return {"message": "Member removed from household"}
