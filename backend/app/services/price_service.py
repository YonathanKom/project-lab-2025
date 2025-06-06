# backend/app/services/price_service.py

import xml.etree.ElementTree as ET
from datetime import datetime
from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func, desc

from ..models.models import Chain, Store, Item, ItemPrice
from ..schemas.schemas import (
    ChainCreate, StoreCreate, ItemCreate, ItemPriceCreate,
    ItemSearchParams, ItemWithPrice, PriceComparisonResponse
)

class PriceService:
    def __init__(self, db: Session):
        self.db = db

    def parse_xml_data(self, xml_content: str) -> Dict[str, Any]:
        """Parse government XML data and extract chain, store, and item information."""
        try:
            root = ET.fromstring(xml_content)
            
            # Extract store information
            chain_id = root.find('ChainId').text if root.find('ChainId') is not None else None
            sub_chain_id = root.find('SubChainId').text if root.find('SubChainId') is not None else None
            store_id = root.find('StoreId').text if root.find('StoreId') is not None else None
            bikoret_no = root.find('BikoretNo').text if root.find('BikoretNo') is not None else None
            
            # Extract items
            items = []
            items_element = root.find('Items')
            if items_element is not None:
                for item_element in items_element.findall('Item'):
                    item_data = self._parse_item_element(item_element)
                    if item_data:
                        items.append(item_data)
            
            return {
                'chain_id': chain_id,
                'sub_chain_id': sub_chain_id,
                'store_id': store_id,
                'bikoret_no': bikoret_no,
                'items': items
            }
        except ET.ParseError as e:
            raise ValueError(f"Invalid XML format: {str(e)}")

    def _parse_item_element(self, item_element: ET.Element) -> Optional[Dict[str, Any]]:
        """Parse individual item element from XML."""
        try:
            # Parse datetime
            price_update_str = item_element.find('PriceUpdateDate').text
            price_update_date = datetime.strptime(price_update_str, '%Y-%m-%d %H:%M:%S')
            
            return {
                'item_code': item_element.find('ItemCode').text,
                'item_type': int(item_element.find('ItemType').text),
                'name': item_element.find('ItemNm').text,
                'manufacturer_name': item_element.find('ManufacturerName').text,
                'manufacture_country': item_element.find('ManufactureCountry').text,
                'manufacturer_description': item_element.find('ManufacturerItemDescription').text,
                'unit_qty': item_element.find('UnitQty').text,
                'quantity': float(item_element.find('Quantity').text) if item_element.find('Quantity').text else None,
                'unit_of_measure': item_element.find('UnitOfMeasure').text.strip() if item_element.find('UnitOfMeasure').text else None,
                'is_weighted': item_element.find('bIsWeighted').text == '1',
                'qty_in_package': float(item_element.find('QtyInPackage').text) if item_element.find('QtyInPackage').text else None,
                'price': float(item_element.find('ItemPrice').text),
                'unit_price': float(item_element.find('UnitOfMeasurePrice').text) if item_element.find('UnitOfMeasurePrice').text else None,
                'allow_discount': item_element.find('AllowDiscount').text == '1',
                'item_status': int(item_element.find('ItemStatus').text),
                'price_update_date': price_update_date
            }
        except (ValueError, AttributeError) as e:
            print(f"Error parsing item element: {str(e)}")
            return None

    def update_data_from_xml(self, xml_content: str, chain_name: str = None) -> Dict[str, int]:
        """Update database with data from government XML."""
        parsed_data = self.parse_xml_data(xml_content)
        
        # Create or update chain
        chain = self._create_or_update_chain(
            parsed_data['chain_id'], 
            chain_name or f"Chain {parsed_data['chain_id']}", 
            parsed_data['sub_chain_id']
        )
        
        # Create or update store
        store = self._create_or_update_store(
            parsed_data['store_id'],
            parsed_data['chain_id'],
            parsed_data['bikoret_no']
        )
        
        # Process items and prices
        items_created = 0
        prices_updated = 0
        
        for item_data in parsed_data['items']:
            # Create or update item
            item = self._create_or_update_item(item_data)
            if item:
                items_created += 1
                
                # Update price
                if self._update_item_price(item.item_code, store.id, item_data):
                    prices_updated += 1
        
        self.db.commit()
        
        return {
            'chains_processed': 1,
            'stores_processed': 1,
            'items_processed': items_created,
            'prices_updated': prices_updated
        }

    def _create_or_update_chain(self, chain_id: str, name: str, sub_chain_id: str = None) -> Chain:
        """Create or update chain record."""
        chain = self.db.query(Chain).filter(Chain.chain_id == chain_id).first()
        
        if not chain:
            chain = Chain(
                chain_id=chain_id,
                name=name,
                sub_chain_id=sub_chain_id
            )
            self.db.add(chain)
            self.db.flush()  # Get the ID
        else:
            chain.name = name
            chain.sub_chain_id = sub_chain_id
            chain.updated_at = func.now()
        
        return chain

    def _create_or_update_store(self, store_id: str, chain_id: str, bikoret_no: str = None) -> Store:
        """Create or update store record."""
        store = self.db.query(Store).filter(
            and_(Store.store_id == store_id, Store.chain_id == chain_id)
        ).first()
        
        if not store:
            store = Store(
                store_id=store_id,
                chain_id=chain_id,
                bikoret_no=bikoret_no
            )
            self.db.add(store)
            self.db.flush()
        else:
            store.bikoret_no = bikoret_no
            store.updated_at = func.now()
        
        return store

    def _create_or_update_item(self, item_data: Dict[str, Any]) -> Optional[Item]:
        """Create or update item record."""
        item = self.db.query(Item).filter(Item.item_code == item_data['item_code']).first()
        
        if not item:
            item = Item(
                item_code=item_data['item_code'],
                item_type=item_data['item_type'],
                name=item_data['name'],
                manufacturer_name=item_data['manufacturer_name'],
                manufacture_country=item_data['manufacture_country'],
                manufacturer_description=item_data['manufacturer_description'],
                unit_qty=item_data['unit_qty'],
                quantity=item_data['quantity'],
                unit_of_measure=item_data['unit_of_measure'],
                is_weighted=item_data['is_weighted'],
                qty_in_package=item_data['qty_in_package'],
                allow_discount=item_data['allow_discount']
            )
            self.db.add(item)
            self.db.flush()
        else:
            # Update item details if they've changed
            item.name = item_data['name']
            item.manufacturer_name = item_data['manufacturer_name']
            item.manufacture_country = item_data['manufacture_country']
            item.manufacturer_description = item_data['manufacturer_description']
            item.unit_qty = item_data['unit_qty']
            item.quantity = item_data['quantity']
            item.unit_of_measure = item_data['unit_of_measure']
            item.is_weighted = item_data['is_weighted']
            item.qty_in_package = item_data['qty_in_package']
            item.allow_discount = item_data['allow_discount']
            item.updated_at = func.now()
        
        return item

    def _update_item_price(self, item_code: str, store_id: int, item_data: Dict[str, Any]) -> bool:
        """Update item price for specific store."""
        # Check if price already exists for this date
        existing_price = self.db.query(ItemPrice).filter(
            and_(
                ItemPrice.item_code == item_code,
                ItemPrice.store_id == store_id,
                ItemPrice.price_update_date == item_data['price_update_date']
            )
        ).first()
        
        if existing_price:
            # Update existing price
            existing_price.price = item_data['price']
            existing_price.unit_price = item_data['unit_price']
            existing_price.item_status = item_data['item_status']
            existing_price.updated_at = func.now()
            return True
        else:
            # Create new price record
            new_price = ItemPrice(
                item_code=item_code,
                store_id=store_id,
                price=item_data['price'],
                unit_price=item_data['unit_price'],
                item_status=item_data['item_status'],
                price_update_date=item_data['price_update_date']
            )
            self.db.add(new_price)
            return True

    def search_items(self, params: ItemSearchParams) -> List[ItemWithPrice]:
        """Search items with current prices."""
        query = self.db.query(Item)
        
        # Apply filters
        if params.query:
            search_term = f"%{params.query}%"
            query = query.filter(
                or_(
                    Item.name.ilike(search_term),
                    Item.manufacturer_description.ilike(search_term),
                    Item.manufacturer_name.ilike(search_term)
                )
            )
        
        # Get items with latest prices
        items = query.offset(params.offset).limit(params.limit).all()
        
        result = []
        for item in items:
            # Get latest price
            latest_price = self.db.query(ItemPrice).filter(
                ItemPrice.item_code == item.item_code
            ).order_by(desc(ItemPrice.price_update_date)).first()
            
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

    def get_price_comparison(self, item_code: str) -> Optional[PriceComparisonResponse]:
        """Get price comparison across all stores for an item."""
        item = self.db.query(Item).filter(Item.item_code == item_code).first()
        if not item:
            return None
        
        # Get all prices for this item
        prices = self.db.query(ItemPrice).filter(
            ItemPrice.item_code == item_code
        ).order_by(desc(ItemPrice.price_update_date)).all()
        
        # Get unique stores
        store_ids = list(set([price.store_id for price in prices]))
        stores = self.db.query(Store).filter(Store.id.in_(store_ids)).all()
        
        return PriceComparisonResponse(
            item=item,
            prices=prices,
            stores=stores
        )