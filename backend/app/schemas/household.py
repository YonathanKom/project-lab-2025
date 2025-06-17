from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .user import UserSummary


class HouseholdBase(BaseModel):
    name: str


class HouseholdCreate(HouseholdBase):
    pass


class HouseholdUpdate(HouseholdBase):
    pass


class HouseholdSummary(HouseholdBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class HouseholdInDBBase(HouseholdBase):
    id: int
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class Household(HouseholdInDBBase):
    members: List["UserSummary"] = []


class UserHouseholdCreate(BaseModel):
    household_id: int
    role: str = "member"


class UserHouseholdUpdate(BaseModel):
    role: Optional[str] = None


class InvitationCreate(BaseModel):
    email: str


class HouseholdInvitationBase(BaseModel):
    household_id: int
    invited_by_id: int
    invited_user_id: int
    status: str


class HouseholdInvitationInDBBase(HouseholdInvitationBase):
    id: int
    created_at: datetime
    responded_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class HouseholdInvitation(HouseholdInvitationInDBBase):
    household: HouseholdSummary
    invited_by: "UserSummary"
    invited_user: "UserSummary"
