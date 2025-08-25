from sqlalchemy.orm import Session
from sqlalchemy import func, desc, and_, or_, text
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Set
import json
import math
from mlxtend.frequent_patterns import apriori, association_rules
import pandas as pd

from app.models import (
    ShoppingListHistory,
    User,
    ItemPrice,
    Store,
    Chain,
    AssociationRule,
)
from app.schemas import ItemPrediction, PredictionReason, PredictionsResponse


class PredictionService:
    def __init__(self, db: Session):
        self.db = db
        self.min_support = 0.01  # Items appearing in at least 1% of transactions
        self.min_confidence = 0.3  # 30% confidence threshold
        self.min_lift = 1.0  # Only rules with positive correlation

    def get_predictions(
        self, user: User, shopping_list_id: Optional[int] = None, limit: int = 10
    ) -> PredictionsResponse:
        """Generate item predictions using Apriori algorithm"""

        # Get all household IDs for the user
        household_ids = [h.id for h in user.households]

        # Get existing items in shopping list
        existing_items = set()
        if shopping_list_id:
            from app.models import ShoppingList

            shopping_list = (
                self.db.query(ShoppingList)
                .filter(ShoppingList.id == shopping_list_id)
                .first()
            )
            if shopping_list:
                existing_items = {item.name.lower() for item in shopping_list.items}

        # Try to use pre-computed rules first
        predictions = self._get_predictions_from_rules(
            household_ids, existing_items, limit
        )

        # If not enough predictions, generate rules on-the-fly
        if len(predictions) < limit:
            self._generate_association_rules(household_ids)
            predictions = self._get_predictions_from_rules(
                household_ids, existing_items, limit
            )

        # Add price information
        for prediction in predictions:
            if prediction.item_code:
                price_info = self._get_best_price(prediction.item_code)
                if price_info:
                    prediction.current_price = price_info["price"]
                    prediction.store_name = price_info["store_name"]
                    prediction.chain_name = price_info["chain_name"]

        return PredictionsResponse(
            shopping_list_id=shopping_list_id,
            predictions=predictions[:limit],
            generated_at=datetime.utcnow(),
        )

    def _get_predictions_from_rules(
        self, household_ids: List[int], existing_items: Set[str], limit: int
    ) -> List[ItemPrediction]:
        """Get predictions from stored association rules"""
        predictions = []
        seen_item_codes = set()  # Track already processed item codes

        # Get item codes for existing items in basket
        existing_item_codes = set()
        if existing_items:
            from app.models import ShoppingItem

            # Get item codes for current basket items
            items_with_codes = (
                self.db.query(ShoppingItem.item_code)
                .filter(
                    and_(
                        ShoppingItem.name.in_(existing_items),
                        ShoppingItem.item_code.isnot(None),
                    )
                )
                .distinct()
                .all()
            )
            existing_item_codes = {
                item.item_code for item in items_with_codes if item.item_code
            }

        # Get recent rules for these households - prioritize household-specific rules
        cutoff_date = datetime.utcnow() - timedelta(days=7)

        rules = (
            self.db.query(AssociationRule)
            .filter(
                and_(
                    or_(
                        AssociationRule.household_id.in_(household_ids),
                        AssociationRule.household_id.is_(None),  # Global rules
                    ),
                    AssociationRule.created_at >= cutoff_date,
                    AssociationRule.confidence >= self.min_confidence,
                )
            )
            .order_by(
                # Prioritize household-specific rules over global rules
                AssociationRule.household_id.desc().nullslast(),
                desc(AssociationRule.confidence),
                desc(AssociationRule.lift),
            )
            .limit(100)
            .all()
        )

        for rule in rules:
            antecedent = set(json.loads(rule.antecedent))
            consequent = set(json.loads(rule.consequent))

            # Check if antecedent items are in current basket (by item code)
            if existing_item_codes and antecedent.issubset(existing_item_codes):
                for item_code in consequent:
                    # Skip if already processed or in existing basket
                    if (
                        item_code not in existing_item_codes
                        and item_code not in seen_item_codes
                    ):
                        # Get item details from catalog
                        from app.models import Item

                        catalog_item = (
                            self.db.query(Item)
                            .filter(Item.item_code == item_code)
                            .first()
                        )

                        if catalog_item:
                            seen_item_codes.add(item_code)  # Mark as processed

                            # Get purchase history
                            item_info = self._get_item_info_by_code(
                                item_code, household_ids
                            )

                            # Get names of antecedent items for display
                            antecedent_names = self._get_item_names(antecedent)

                            predictions.append(
                                ItemPrediction(
                                    item_code=item_code,
                                    item_name=catalog_item.name,
                                    confidence_score=rule.confidence,
                                    reason=PredictionReason.APRIORI_ASSOCIATION,
                                    reason_detail=f"Frequently bought with {', '.join(antecedent_names)}",
                                    last_purchased=item_info.get("last_purchased"),
                                    purchase_count=item_info.get("purchase_count", 0),
                                    avg_quantity=item_info.get("avg_quantity", 1.0),
                                    suggested_quantity=item_info.get(
                                        "suggested_quantity", 1
                                    ),
                                    current_price=None,
                                    store_name=None,
                                    chain_name=None,
                                )
                            )

        # If no items in basket or not enough predictions, use most frequent items
        if len(predictions) < limit:
            frequent_predictions = self._get_frequent_items_predictions(
                household_ids,
                existing_items.union(seen_item_codes),
                limit - len(predictions),
            )
            predictions.extend(frequent_predictions)

        return predictions

    def _generate_association_rules(self, household_ids: List[int]) -> None:
        """Generate and store association rules using Apriori algorithm"""

        # Get transaction data from shopping list history
        transactions = self._get_transactions(household_ids)

        # Convert to binary matrix for mlxtend
        df = self._create_transaction_matrix(transactions)

        if df.empty:
            return

        try:
            # Generate frequent itemsets
            frequent_itemsets = apriori(
                df,
                min_support=self.min_support,
                use_colnames=True,
                max_len=3,  # Limit to 3-item sets for performance
            )

            if frequent_itemsets.empty:
                return

            # Generate association rules
            rules = association_rules(
                frequent_itemsets,
                metric="confidence",
                min_threshold=self.min_confidence,
                support_only=False,
            )

            # Filter by lift
            rules = rules[rules["lift"] >= self.min_lift]

            # Store rules in database
            self._store_rules(
                rules, household_ids[0] if len(household_ids) == 1 else None
            )

        except Exception as e:
            # Log error but don't fail
            print(f"Error generating association rules: {e}")

    def _get_transactions(self, household_ids: List[int]) -> List[List[str]]:
        """Get transaction data from shopping list history using item codes"""

        # Get completed shopping lists from last 90 days
        since_date = datetime.utcnow() - timedelta(days=90)

        history_items = (
            self.db.query(ShoppingListHistory)
            .filter(
                and_(
                    ShoppingListHistory.household_id.in_(household_ids),
                    ShoppingListHistory.completed_at >= since_date,
                )
            )
            .all()
        )

        transactions = []
        for history in history_items:
            items_data = json.loads(history.items_data)
            # Extract item codes from the history (only for items with codes)
            transaction = [
                item["item_code"]
                for item in items_data
                if item.get("is_purchased", True) and item.get("item_code")
            ]
            if (
                len(transaction) >= 2
            ):  # Only use transactions with at least 2 items with codes
                transactions.append(transaction)

        return transactions

    def _create_transaction_matrix(self, transactions: List[List[str]]) -> pd.DataFrame:
        """Convert transactions to binary matrix for Apriori"""

        # Get all unique items
        all_items = set()
        for transaction in transactions:
            all_items.update(transaction)

        # Create binary matrix
        data = []
        for transaction in transactions:
            row = {item: (item in transaction) for item in all_items}
            data.append(row)

        return pd.DataFrame(data).fillna(False)

    def _store_rules(self, rules: pd.DataFrame, household_id: Optional[int]) -> None:
        """Store association rules in database"""

        # Delete old rules for this household
        if household_id:
            self.db.query(AssociationRule).filter(
                AssociationRule.household_id == household_id
            ).delete()
        else:
            # Delete old global rules
            self.db.query(AssociationRule).filter(
                AssociationRule.household_id.is_(None)
            ).delete()

        # Store new rules
        for _, rule in rules.iterrows():
            antecedent = list(rule["antecedents"])
            consequent = list(rule["consequents"])

            new_rule = AssociationRule(
                antecedent=json.dumps(antecedent),
                consequent=json.dumps(consequent),
                support=float(rule["support"]),
                confidence=float(rule["confidence"]),
                lift=float(rule["lift"]),
                household_id=household_id,
            )
            self.db.add(new_rule)

        self.db.commit()

    def _get_frequent_items_predictions(
        self, household_ids: List[int], existing_items: Set[str], limit: int
    ) -> List[ItemPrediction]:
        """Get predictions based on most frequently purchased items with item codes"""

        since_date = datetime.utcnow() - timedelta(days=30)

        # Query frequent items with item codes from history
        frequent_items = self.db.execute(
            text("""
                SELECT 
                    item->>'item_code' as item_code,
                    item->>'name' as item_name,
                    COUNT(*) as purchase_count,
                    AVG(CAST(item->>'quantity' AS FLOAT)) as avg_quantity,
                    MAX(completed_at) as last_purchased
                FROM shopping_list_history,
                    jsonb_array_elements(items_data::jsonb) as item
                WHERE household_id IN :household_ids
                AND completed_at >= :since_date
                AND (item->>'is_purchased')::boolean = true
                AND item->>'item_code' IS NOT NULL
                GROUP BY item->>'item_code', item->>'name'
                ORDER BY purchase_count DESC
                LIMIT :limit
            """),
            {
                "household_ids": tuple(household_ids),
                "since_date": since_date,
                "limit": limit * 2,
            },
        ).fetchall()

        predictions = []
        seen_item_codes = set()  # Track processed item codes for this method too

        for row in frequent_items:
            item_code = row[0]
            item_name = row[1]

            # Skip if item is already in basket or already processed
            if (
                item_name.lower() not in existing_items
                and item_code not in seen_item_codes
            ):
                seen_item_codes.add(item_code)

                # Base confidence on frequency
                confidence = min(0.7, 0.3 + (row[2] * 0.05))  # row[2] is purchase_count

                predictions.append(
                    ItemPrediction(
                        item_code=item_code,
                        item_name=item_name,
                        confidence_score=confidence,
                        reason=PredictionReason.APRIORI_ASSOCIATION,
                        reason_detail=f"Frequently purchased item (bought {row[2]} times recently)",
                        last_purchased=row[4],  # last_purchased
                        purchase_count=row[2],  # purchase_count
                        avg_quantity=float(row[3]) if row[3] else 1.0,  # avg_quantity
                        suggested_quantity=math.ceil(row[3]) if row[3] else 1,
                        current_price=None,
                        store_name=None,
                        chain_name=None,
                    )
                )

                if len(predictions) >= limit:
                    break

        return predictions

    def _get_item_info(self, item_name: str, household_ids: List[int]) -> Dict:
        """Get purchase history info for an item"""

        result = self.db.execute(
            text("""
                SELECT 
                    item->>'item_code' as item_code,
                    COUNT(*) as purchase_count,
                    AVG(CAST(item->>'quantity' AS FLOAT)) as avg_quantity,
                    MAX(completed_at) as last_purchased
                FROM shopping_list_history,
                     jsonb_array_elements(items_data::jsonb) as item
                WHERE household_id IN :household_ids
                  AND LOWER(item->>'name') = :item_name
                  AND (item->>'is_purchased')::boolean = true
                GROUP BY item->>'item_code'
                LIMIT 1
            """),
            {"household_ids": tuple(household_ids), "item_name": item_name.lower()},
        ).first()

        if result:
            return {
                "item_code": result.item_code,
                "purchase_count": result.purchase_count,
                "avg_quantity": float(result.avg_quantity)
                if result.avg_quantity
                else 1.0,
                "suggested_quantity": math.ceil(result.avg_quantity)
                if result.avg_quantity
                else 1,
                "last_purchased": result.last_purchased,
            }

        return {"purchase_count": 0, "avg_quantity": 1.0, "suggested_quantity": 1}

    def _get_best_price(self, item_code: str) -> Optional[dict]:
        """Get the best current price for an item"""
        best_price = (
            self.db.query(
                ItemPrice.price,
                Store.name.label("store_name"),
                Chain.name.label("chain_name"),
            )
            .join(Store, ItemPrice.store_id == Store.id)
            .join(Chain, Store.chain_id == Chain.chain_id)
            .filter(and_(ItemPrice.item_code == item_code, ItemPrice.item_status == 1))
            .order_by(ItemPrice.price.asc())
            .first()
        )

        if best_price:
            return {
                "price": best_price.price,
                "store_name": best_price.store_name,
                "chain_name": best_price.chain_name,
            }
        return None

    def generate_all_rules(self) -> Dict[str, int]:
        """Generate association rules for all households - called by API endpoint"""

        # Get all households
        households = self.db.execute(
            text("""
                SELECT DISTINCT household_id, COUNT(*) as history_count
                FROM shopping_list_history
                WHERE completed_at >= :since_date
                GROUP BY household_id
            """),
            {"since_date": datetime.utcnow() - timedelta(days=90)},
        ).fetchall()

        total_rules = 0
        households_processed = 0

        for household in households:
            self._generate_association_rules([household.household_id])
            households_processed += 1

        # Also generate global rules using all data
        all_household_ids = [h.household_id for h in households]
        if all_household_ids:
            self._generate_association_rules(all_household_ids)

        # Count total rules generated
        total_rules = self.db.query(func.count(AssociationRule.id)).scalar()

        return {
            "households_processed": households_processed,
            "total_rules_generated": total_rules,
        }

    def _get_item_info_by_code(self, item_code: str, household_ids: List[int]) -> Dict:
        """Get purchase history info for an item by code"""

        result = self.db.execute(
            text("""
                SELECT 
                    COUNT(*) as purchase_count,
                    AVG(CAST(item->>'quantity' AS FLOAT)) as avg_quantity,
                    MAX(completed_at) as last_purchased
                FROM shopping_list_history,
                    jsonb_array_elements(items_data::jsonb) as item
                WHERE household_id IN :household_ids
                AND item->>'item_code' = :item_code
                AND (item->>'is_purchased')::boolean = true
                GROUP BY item->>'item_code'
                LIMIT 1
            """),
            {"household_ids": tuple(household_ids), "item_code": item_code},
        ).first()

        if result:
            return {
                "purchase_count": result.purchase_count,
                "avg_quantity": float(result.avg_quantity)
                if result.avg_quantity
                else 1.0,
                "suggested_quantity": math.ceil(result.avg_quantity)
                if result.avg_quantity
                else 1,
                "last_purchased": result.last_purchased,
            }

        return {"purchase_count": 0, "avg_quantity": 1.0, "suggested_quantity": 1}

    def _get_item_names(self, item_codes: Set[str]) -> List[str]:
        """Get item names for a set of item codes"""
        from app.models import Item

        items = self.db.query(Item.name).filter(Item.item_code.in_(item_codes)).all()
        return [item.name for item in items] if items else list(item_codes)
