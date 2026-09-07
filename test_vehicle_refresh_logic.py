"""
Comprehensive test suite for Vehicle refresh logic based on latest Refuel by date.

Tests the centralized refresh_vehicle_from_latest_refuel() function
and ensures that Vehicle.last_odometer always reflects the true latest refuel
by date, not by insertion order.
"""

from datetime import date
from sqlmodel import Session, create_engine
from sqlmodel import SQLModel

from app.models.vehicle import Vehicle, VehicleCreate
from app.models.refuel import Refuel, RefuelCreate
from app.models.mission import Mission, MissionExpense
from app.models.store import CardConsumption, InventoryDiscount
from app.crud.refuel import create_refuel, delete_refuel_with_reverse, refresh_vehicle_from_latest_refuel
from app.crud.mission import complete_mission, delete_mission_expense, delete_mission


# Setup test database
DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SQLModel.metadata.create_all(engine)


def get_db_session():
    """Get a test database session"""
    with Session(engine) as session:
        return session


class TestVehicleRefreshLogic:
    """Test cases for Vehicle refresh logic"""
    
    def setup_method(self):
        """Setup before each test"""
        SQLModel.metadata.drop_all(engine)
        SQLModel.metadata.create_all(engine)
    
    def test_1_add_newer_refuel_updates_vehicle(self):
        """
        TEST 1: Adding a refuel with a NEWER date than existing refuels
        should update Vehicle
        
        Expected: Vehicle.last_odometer updates to new value
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="123",
            letters="أ",
            vehicle_type="سيارة",
            fuel_type="ديزل",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Add first refuel: 2026-08-01, odometer 50000
        refuel1 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50000,
            liters=100,
            created_at=date(2026, 8, 1),
        )
        create_refuel(db, refuel1)
        
        # Check Vehicle is updated
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50000
        assert vehicle.last_odometer_date == date(2026, 8, 1)
        
        # Add second refuel with NEWER date: 2026-08-03, odometer 50300
        refuel2 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50300,
            liters=50,
            created_at=date(2026, 8, 3),
        )
        create_refuel(db, refuel2)
        
        # Check Vehicle is updated to the newer refuel
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50300, f"Expected 50300, got {vehicle.last_odometer}"
        assert vehicle.last_odometer_date == date(2026, 8, 3)
        print("✓ TEST 1 PASSED: Newer refuel updates Vehicle")
    
    def test_2_add_older_refuel_does_not_update_vehicle(self):
        """
        TEST 2: Adding a refuel with an OLDER date than existing refuels
        should NOT update Vehicle
        
        Scenario:
        - Refuel on 2026-08-01 (odometer 50000)
        - Refuel on 2026-08-03 (odometer 50300)
        - Add refuel on 2026-07-30 (odometer 49700) ← OLDER DATE
        
        Expected: Vehicle remains at 2026-08-03, 50300
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="124",
            letters="ب",
            vehicle_type="سيارة",
            fuel_type="ديزل",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Add first refuel: 2026-08-01
        refuel1 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50000,
            liters=100,
            created_at=date(2026, 8, 1),
        )
        create_refuel(db, refuel1)
        
        # Add second refuel: 2026-08-03 (newer)
        refuel2 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50300,
            liters=50,
            created_at=date(2026, 8, 3),
        )
        create_refuel(db, refuel2)
        
        # Verify state before adding old refuel
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50300
        assert vehicle.last_odometer_date == date(2026, 8, 3)
        
        # Add refuel with OLDER date: 2026-07-30
        refuel3 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=49700,
            liters=60,
            created_at=date(2026, 7, 30),
        )
        create_refuel(db, refuel3)
        
        # Check Vehicle is NOT updated (still at 2026-08-03)
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50300, f"Expected 50300, got {vehicle.last_odometer}"
        assert vehicle.last_odometer_date == date(2026, 8, 3), \
            f"Expected date(2026, 8, 3), got {vehicle.last_odometer_date}"
        
        # Verify all refuels exist in database
        refuels = db.exec(__import__("sqlmodel").select(Refuel).where(Refuel.vehicle_id == vehicle_id)).all()
        assert len(refuels) == 3, f"Expected 3 refuels, got {len(refuels)}"
        
        print("✓ TEST 2 PASSED: Older refuel does not update Vehicle")
    
    def test_3_delete_latest_refuel_returns_to_previous(self):
        """
        TEST 3: Deleting the latest refuel should make Vehicle point to 
        the previous (older) latest refuel
        
        Scenario:
        - Refuel 2026-08-01: 50000
        - Refuel 2026-08-03: 50300 ← LATEST
        
        After deleting 2026-08-03:
        - Vehicle should return to 2026-08-01: 50000
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="125",
            letters="ج",
            vehicle_type="سيارة",
            fuel_type="ديزل",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Add two refuels
        refuel1 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50000,
            liters=100,
            created_at=date(2026, 8, 1),
        )
        r1 = create_refuel(db, refuel1)
        
        refuel2 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50300,
            liters=50,
            created_at=date(2026, 8, 3),
        )
        r2 = create_refuel(db, refuel2)
        
        # Verify Vehicle is at latest
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50300
        
        # Delete the latest refuel (2026-08-03)
        delete_refuel_with_reverse(db, r2.id)
        
        # Check Vehicle returns to first refuel
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50000, f"Expected 50000, got {vehicle.last_odometer}"
        assert vehicle.last_odometer_date == date(2026, 8, 1)
        print("✓ TEST 3 PASSED: Delete latest refuel returns to previous")
    
    def test_4_delete_old_refuel_does_not_change_vehicle(self):
        """
        TEST 4: Deleting an old refuel should NOT change Vehicle 
        if newer refuels exist
        
        Scenario:
        - Refuel 2026-08-01: 50000 ← DELETE THIS
        - Refuel 2026-08-03: 50300 ← LATEST
        
        After deleting 2026-08-01:
        - Vehicle should remain at 2026-08-03: 50300
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="126",
            letters="د",
            vehicle_type="سيارة",
            fuel_type="ديزل",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Add two refuels
        refuel1 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50000,
            liters=100,
            created_at=date(2026, 8, 1),
        )
        r1 = create_refuel(db, refuel1)
        
        refuel2 = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50300,
            liters=50,
            created_at=date(2026, 8, 3),
        )
        r2 = create_refuel(db, refuel2)
        
        # Verify Vehicle is at latest
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50300
        
        # Delete the old refuel (2026-08-01)
        delete_refuel_with_reverse(db, r1.id)
        
        # Check Vehicle is still at newest refuel
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50300, f"Expected 50300, got {vehicle.last_odometer}"
        assert vehicle.last_odometer_date == date(2026, 8, 3)
        print("✓ TEST 4 PASSED: Delete old refuel does not change Vehicle")
    
    def test_5_delete_mission_updates_vehicle(self):
        """
        TEST 5: Deleting a completed mission with multiple refuels 
        should update Vehicle to the latest remaining refuel
        
        Scenario:
        - Non-mission refuel 2026-08-01: 50000
        - Mission refuel 2026-08-03: 50300
        - Mission refuel 2026-08-05: 50500 ← DELETE MISSION
        
        After deleting mission:
        - Vehicle should point to 2026-08-03: 50300
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="127",
            letters="ه",
            vehicle_type="سيارة",
            fuel_type="سولار",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Add base refuel
        refuel_base = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50000,
            liters=100,
            created_at=date(2026, 8, 1),
        )
        create_refuel(db, refuel_base)
        
        # Create mission
        mission = Mission(
            vehicle_id=vehicle_id,
            fuel_type="سولار",
            status="open",
        )
        db.add(mission)
        db.commit()
        db.refresh(mission)
        
        # Add expenses to mission
        exp1 = MissionExpense(
            mission_id=mission.id,
            date=date(2026, 8, 3),
            odometer=50300,
            liters=50,
        )
        db.add(exp1)
        db.commit()
        db.refresh(exp1)
        
        exp2 = MissionExpense(
            mission_id=mission.id,
            date=date(2026, 8, 5),
            odometer=50500,
            liters=50,
        )
        db.add(exp2)
        db.commit()
        db.refresh(exp2)
        
        # Complete mission (creates refuels)
        complete_mission(db, mission.id)
        
        # Verify Vehicle is at latest
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50500, f"Expected 50500, got {vehicle.last_odometer}"
        
        # Delete the mission
        delete_mission(db, mission.id)
        
        # Check Vehicle returns to base refuel
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50000, f"Expected 50000, got {vehicle.last_odometer}"
        assert vehicle.last_odometer_date == date(2026, 8, 1)
        print("✓ TEST 5 PASSED: Delete mission updates Vehicle correctly")
    
    def test_6_all_paths_use_same_logic(self):
        """
        TEST 6: Adding refuel from different paths (direct, mission) 
        should use the same logic
        
        This test verifies that all three UI paths:
        - صفحة المتابعة (direct refuel)
        - صفحة المخزن (direct refuel)
        - صفحة المأموريات (mission refuel)
        
        All produce the same result when adding refuels with older dates.
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="128",
            letters="و",
            vehicle_type="سيارة",
            fuel_type="سولار",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Path 1: Direct refuel (صفحة المتابعة / المخزن)
        refuel_direct = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=50000,
            liters=100,
            created_at=date(2026, 8, 3),
        )
        create_refuel(db, refuel_direct)
        
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50000
        
        # Now add older refuel - should not update Vehicle
        refuel_old = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=49700,
            liters=60,
            created_at=date(2026, 8, 1),
        )
        create_refuel(db, refuel_old)
        
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50000, "Direct refuel path failed on old date"
        
        # Path 2: Mission refuel (صفحة المأموريات)
        mission = Mission(
            vehicle_id=vehicle_id,
            fuel_type="سولار",
            status="open",
        )
        db.add(mission)
        db.commit()
        db.refresh(mission)
        
        # Add mission expense with OLD date
        exp = MissionExpense(
            mission_id=mission.id,
            date=date(2026, 7, 30),
            odometer=49500,
            liters=50,
        )
        db.add(exp)
        db.commit()
        db.refresh(exp)
        
        # Complete mission - should not change Vehicle date logic
        complete_mission(db, mission.id)
        
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 50000, "Mission refuel path failed: Vehicle changed"
        assert vehicle.last_odometer_date == date(2026, 8, 3), \
            "Mission refuel should not change latest date"
        
        print("✓ TEST 6 PASSED: All paths use same centralized logic")
    
    def test_7_ismailia_scenario(self):
        """
        TEST 7: Real-world Ismailia scenario with backdated fuel entries
        
        Scenario that actually happens in production:
        - Record fuel on 2026-08-20 (odometer 100000) - latest known
        - Discover fuel was delivered on 2026-08-19 but not recorded
        - Add backdated fuel: 2026-08-19 (odometer 99800)
        
        Expected:
        - Both fuel entries exist in database
        - Vehicle still points to 2026-08-20 (99800 is older date)
        
        Then delete 2026-08-20:
        - Vehicle should update to 2026-08-19 entry
        """
        db = get_db_session()
        
        # Create vehicle
        vehicle = Vehicle(
            number="1000",
            letters="ع",
            vehicle_type="سيارة",
            fuel_type="سولار",
            standard_consumption=7.5,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id
        
        # Record fuel on 2026-08-20
        refuel_main = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=100000,
            liters=200,
            created_at=date(2026, 8, 20),
            station="إسماعيلية",
        )
        r_main = create_refuel(db, refuel_main)
        
        # Verify Vehicle
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 100000
        assert vehicle.last_odometer_date == date(2026, 8, 20)
        
        # Later, discover missing fuel on 2026-08-19, add it (backdated)
        refuel_ismailia = RefuelCreate(
            vehicle_id=vehicle_id,
            current_odometer=99800,
            liters=150,
            created_at=date(2026, 8, 19),
            station="إسماعيلية",
        )
        r_ismailia = create_refuel(db, refuel_ismailia)
        
        # Vehicle should STILL point to 2026-08-20 (later date)
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 100000, \
            f"Vehicle incorrectly updated to old date. Got {vehicle.last_odometer}, expected 100000"
        assert vehicle.last_odometer_date == date(2026, 8, 20)
        
        # Verify both refuels exist
        refuels = db.exec(__import__("sqlmodel").select(Refuel).where(Refuel.vehicle_id == vehicle_id)).all()
        assert len(refuels) == 2
        
        # Now delete 2026-08-20 fuel (maybe it was a duplicate)
        delete_refuel_with_reverse(db, r_main.id)
        
        # Vehicle should now point to 2026-08-19
        vehicle = db.get(Vehicle, vehicle_id)
        assert vehicle.last_odometer == 99800, \
            f"After deletion, expected 99800, got {vehicle.last_odometer}"
        assert vehicle.last_odometer_date == date(2026, 8, 19)
        
        print("✓ TEST 7 PASSED: Ismailia backdated scenario works correctly")

    def test_8_persisted_vehicle_state_in_fresh_session_after_create_and_delete(self):
        """Verify Vehicle values are saved to database and readable from a completely new Session."""
        db = get_db_session()

        vehicle = Vehicle(
            number="2000",
            letters="ز",
            vehicle_type="سيارة",
            fuel_type="ديزل",
            standard_consumption=8.0,
        )
        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)
        vehicle_id = vehicle.id

        create_refuel(
            db,
            RefuelCreate(
                vehicle_id=vehicle_id,
                current_odometer=100000,
                liters=100,
                created_at=date(2026, 8, 20),
            ),
        )
        create_refuel(
            db,
            RefuelCreate(
                vehicle_id=vehicle_id,
                current_odometer=99800,
                liters=120,
                created_at=date(2026, 8, 19),
            ),
        )

        with Session(engine) as fresh_db:
            fresh_vehicle = fresh_db.get(Vehicle, vehicle_id)
            assert fresh_vehicle is not None
            assert fresh_vehicle.last_odometer == 100000
            assert fresh_vehicle.last_odometer_date == date(2026, 8, 20)

        refuels = db.exec(__import__("sqlmodel").select(Refuel).where(Refuel.vehicle_id == vehicle_id).order_by(Refuel.created_at.desc(), Refuel.id.desc())).all()
        latest_refuel = refuels[0]
        delete_refuel_with_reverse(db, latest_refuel.id)

        with Session(engine) as fresh_db_after_delete:
            fresh_vehicle_after_delete = fresh_db_after_delete.get(Vehicle, vehicle_id)
            assert fresh_vehicle_after_delete is not None
            assert fresh_vehicle_after_delete.last_odometer == 99800, (
                f"Expected persisted last_odometer=99800 after delete, got {fresh_vehicle_after_delete.last_odometer}"
            )
            assert fresh_vehicle_after_delete.last_odometer_date == date(2026, 8, 19), (
                f"Expected persisted date 2026-08-19 after delete, got {fresh_vehicle_after_delete.last_odometer_date}"
            )

        print("✓ TEST 8 PASSED: Vehicle state persisted in fresh Session after create and delete")


def run_all_tests():
    """Run all tests"""
    print("\n" + "="*70)
    print("RUNNING COMPREHENSIVE VEHICLE REFRESH LOGIC TESTS")
    print("="*70 + "\n")
    
    test_suite = TestVehicleRefreshLogic()
    tests = [
        test_suite.test_1_add_newer_refuel_updates_vehicle,
        test_suite.test_2_add_older_refuel_does_not_update_vehicle,
        test_suite.test_3_delete_latest_refuel_returns_to_previous,
        test_suite.test_4_delete_old_refuel_does_not_change_vehicle,
        test_suite.test_5_delete_mission_updates_vehicle,
        test_suite.test_6_all_paths_use_same_logic,
        test_suite.test_7_ismailia_scenario,
    ]
    
    passed = 0
    failed = 0
    
    for test_func in tests:
        test_suite.setup_method()
        try:
            test_func()
            passed += 1
        except AssertionError as e:
            failed += 1
            print(f"✗ {test_func.__name__} FAILED: {str(e)}")
        except Exception as e:
            failed += 1
            print(f"✗ {test_func.__name__} ERROR: {str(e)}")
    
    print("\n" + "="*70)
    print(f"TEST RESULTS: {passed} PASSED, {failed} FAILED")
    print("="*70 + "\n")
    
    return failed == 0


if __name__ == "__main__":
    success = run_all_tests()
    exit(0 if success else 1)
