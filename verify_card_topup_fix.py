from datetime import date
from sqlmodel import Session, SQLModel, create_engine, select

from backend.app.models.store import AddInvoice, CardTopUp, InventoryDiscount
from backend.app.crud.store import create_card_topup, get_store_balances

engine = create_engine('sqlite:///:memory:')
SQLModel.metadata.create_all(engine)

with Session(engine) as db:
    invoice = AddInvoice(
        invoice_number='TEST-VERIFY',
        created_at=date.today(),
        solar_quantity=1000.0,
        solar_price=1.0,
        solar_total=1000.0,
    )
    db.add(invoice)
    db.commit()

    create_card_topup(db, CardTopUp(created_at=date.today(), fuel_type='سولار', liters=100.0, note='verify'))

    balances = get_store_balances(db)
    discount_rows = db.exec(select(InventoryDiscount).where(InventoryDiscount.fuel_type == 'سولار')).all()
    card_balance = balances.get('cards', {}).get('solar', 0.0)
    store_balance = balances.get('solar', 0.0)
    print(f'store_before={1000.0} store_after={store_balance} card={card_balance} discount_count={len(discount_rows)} discount_liters={sum(float(r.liters or 0.0) for r in discount_rows)}')
    assert store_balance == 1000.0, store_balance
    assert card_balance == 100.0, card_balance
    assert len(discount_rows) == 1, len(discount_rows)
    assert discount_rows[0].liters == 100.0, discount_rows[0].liters

with open('card_topup_verification.txt', 'w', encoding='utf-8') as f:
    f.write('OK')
