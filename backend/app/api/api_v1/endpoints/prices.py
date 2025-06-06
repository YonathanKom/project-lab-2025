# backend/app/api/api_v1/endpoints/prices.py

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy import func, desc, select
from sqlalchemy.orm import Session, aliased
from typing import List, Optional

from ....core.database import get_db
from ....services.price_service import PriceService
from ....schemas.schemas import (
    Chain, Store, Item, ItemWithPrice, ItemSearchParams, 
    PriceComparisonResponse
)
from ....api.deps import get_current_user
from ....models.models import User

router = APIRouter()

@router.post("/upload-xml/", response_model=dict)
async def upload_price_data(
    file: UploadFile = File(...),
    chain_name: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Upload government XML price data to update items and prices."""
    if not file.filename.endswith('.xml'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be XML format"
        )
    
    try:
        content = await file.read()
        xml_content = content.decode('utf-8')
        
        price_service = PriceService(db)
        result = price_service.update_data_from_xml(xml_content, chain_name)
        
        return {
            "message": "Data uploaded successfully",
            "filename": file.filename,
            "statistics": result
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing XML file: {str(e)}"
        )

@router.get("/chains/", response_model=List[Chain])
def get_chains(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all available chains."""
    from ....models.models import Chain as ChainModel
    chains = db.query(ChainModel).offset(skip).limit(limit).all()
    return chains

@router.get("/stores/", response_model=List[Store])
def get_stores(
    chain_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get stores, optionally filtered by chain."""
    from ....models.models import Store as StoreModel
    
    query = db.query(StoreModel)
    if chain_id:
        query = query.filter(StoreModel.chain_id == chain_id)
    
    stores = query.offset(skip).limit(limit).all()
    return stores

@router.get("/items/search/", response_model=List[ItemWithPrice])
def search_items(
    query: Optional[str] = None,
    chain_id: Optional[str] = None,
    store_id: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Search items with current prices."""
    search_params = ItemSearchParams(
        query=query,
        chain_id=chain_id,
        store_id=store_id,
        min_price=min_price,
        max_price=max_price,
        offset=skip,
        limit=limit
    )
    
    price_service = PriceService(db)
    return price_service.search_items(search_params)

@router.get("/items/{item_code}/", response_model=Item)
def get_item(
    item_code: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get item details by item code."""
    from ....models.models import Item as ItemModel
    
    item = db.query(ItemModel).filter(ItemModel.item_code == item_code).first()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found"
        )
    return item

@router.get("/items/{item_code}/compare-prices/", response_model=PriceComparisonResponse)
def compare_item_prices(
    item_code: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get price comparison across all stores for an item."""
    price_service = PriceService(db)
    comparison = price_service.get_price_comparison(item_code)
    
    if not comparison:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item not found"
        )
    
    return comparison

@router.get("/popular-items/", response_model=List[ItemWithPrice])
def get_popular_items(
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from ....models.models import Item as ItemModel, ItemPrice

    # Step 1: Subquery to get most popular item codes by price count
    subq = (
        db.query(ItemPrice.item_code, func.count(ItemPrice.id).label('price_count'))
        .group_by(ItemPrice.item_code)
        .order_by(desc('price_count'))
        .limit(limit)
        .subquery()
    )

    # Step 2: Join with items to fetch full details
    popular_items_query = (
        db.query(ItemModel)
        .join(subq, ItemModel.item_code == subq.c.item_code)
        .order_by(desc(subq.c.price_count))
    )

    popular_items = popular_items_query.all()

    # Step 3: Enrich items with latest price
    result = []
    for item in popular_items:
        latest_price = (
            db.query(ItemPrice)
            .filter(ItemPrice.item_code == item.item_code)
            .order_by(desc(ItemPrice.price_update_date))
            .first()
        )

        item_with_price = ItemWithPrice(
            id=item.id,
            item_code=item.item_code,
            item_type=item.item_type,
            name=item.name,
            manufacturer_name=item.manufacturer_name,
            manufacture_country=item.manufacture_country,
            manufacturer_description=item.manufacturer_description,
            unit_qty=item.unit_qty,
            quantity=item.quantity,
            unit_of_measure=item.unit_of_measure,
            is_weighted=item.is_weighted,
            qty_in_package=item.qty_in_package,
            allow_discount=item.allow_discount,
            created_at=item.created_at,
            updated_at=item.updated_at,
            current_price=latest_price.price if latest_price else None,
            price_update_date=latest_price.price_update_date if latest_price else None
        )
        result.append(item_with_price)

    return result