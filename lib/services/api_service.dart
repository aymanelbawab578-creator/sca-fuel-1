import 'dart:typed_data';

import '../models/vehicle.dart';
import '../models/refuel.dart';
import '../config/app_config.dart';
import 'direct_database/vehicle_service.dart';
import 'direct_database/gas_record_service.dart';
import 'direct_database/store_service.dart';
import 'direct_database/refuel_service.dart';
import 'direct_database/mission_service.dart';
import 'direct_database/invoice_service.dart';
import 'direct_database/report_service.dart';
import 'direct_database/card_delivery_service.dart';
import 'direct_database/user_service.dart';
import 'direct_database/model_config_service.dart';
import 'direct_database/archive_service.dart';
import 'direct_database/auth_service.dart';

class ApiService {
  static Future<String> login(String username, String password) async {
    return DirectDatabaseAuthService.login(username, password);
  }

  static Future<List<Vehicle>> fetchVehicles(
      String token, String query) async {
    return DirectVehicleService.search(query);
  }

  static Future<Vehicle> updateVehiclePlate(
      String token, int id, String number, String? letters) async {
    return DirectVehicleService.updatePlate(id, number, letters);
  }

  static Future<List<Map<String, dynamic>>> listVehiclePlateChanges(
      String token) async {
    return DirectVehicleService.listPlateChanges();
  }

  static Future<Map<String, dynamic>> updateVehiclePlateChange(
      String token, int changeId, String number, String? letters) async {
    return DirectVehicleService.updatePlateChange(
      changeId,
      number,
      letters,
    );
  }

  static Future<void> deleteVehiclePlateChange(
      String token, int changeId) async {
    return DirectVehicleService.deletePlateChange(changeId);
  }

  static Future<List<Map<String, dynamic>>> listGasRecords(
    String token, {
    String? startDate,
    String? endDate,
  }) async {
    return DirectGasRecordService.list(
      startDate: startDate,
      endDate: endDate,
    );
  }

  static Future<Map<String, dynamic>> createGasRecord(
      String token, Map<String, dynamic> payload) async {
    return DirectGasRecordService.create(payload);
  }

  static Future<Map<String, dynamic>> updateGasRecord(
      String token, int id, Map<String, dynamic> payload) async {
    return DirectGasRecordService.update(id, payload);
  }

  static Future<void> deleteGasRecord(String token, int id) async {
    return DirectGasRecordService.delete(id);
  }

  static Future<List<Map<String, dynamic>>> getGasReport(
    String token, {
    required String fromDate,
    required String toDate,
    String? vehicleNumber,
  }) async {
    return DirectGasRecordService.report(
      fromDate: fromDate,
      toDate: toDate,
      vehicleNumber: vehicleNumber,
    );
  }

  static Future<Vehicle> getVehicleDetail(
      String token, int id) async {
    return DirectVehicleService.getById(id);
  }

  static Future<List<Refuel>> fetchRefuels(
      String token, int vehicleId) async {
    return DirectRefuelService.listByVehicle(vehicleId);
  }

  static Future<Refuel> submitRefuel(
      String token, RefuelCreate refuel) async {
    return DirectRefuelService.create(refuel);
  }

  static Future<Refuel> updateRefuel(
      String token, int refuelId, RefuelCreate refuel) async {
    return DirectRefuelService.update(refuelId, refuel);
  }

  static Future<void> deleteRefuel(
      String token, int refuelId) async {
    return DirectRefuelService.delete(refuelId);
  }

  static Future<List<Vehicle>> listVehicles(
    String token, {
    String? query,
    int? limit,
    int? offset,
  }) async {
    return DirectVehicleService.list(
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  /// Paged listing that also attempts to return the total matching count.
  /// The returned map contains keys: 'items' -> List<Vehicle>, 'total' -> int
  static Future<Map<String, dynamic>> listVehiclesPaged(
    String token, {
    String? query,
    int? limit,
    int? offset,
  }) async {
    return DirectVehicleService.listPaged(
      query: query,
      limit: limit,
      offset: offset,
    );
  }

  static Future<Vehicle> createVehicle(
      String token, Map<String, dynamic> vehicleJson) async {
    return DirectVehicleService.create(vehicleJson);
  }

  static Future<List<Vehicle>> createVehicles(
      String token, List<Map<String, dynamic>> vehiclesJson) async {
    return DirectVehicleService.createBatch(vehiclesJson);
  }

  // ============================================================
  // Reports
  // ============================================================

  static Future<Map<String, dynamic>> fetchDashboardSummary(
      String token) async {
    return DirectReportService.dashboard();
  }

  static Future<Map<String, dynamic>> getDailyReport(
      String token, DateTime date) async {
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')
        .first;

    return DirectReportService.daily(dateStr);
  }

  static Future<Map<String, dynamic>> getRangeReport(
      String token, DateTime start, DateTime end) async {
    return DirectReportService.range(
      _dateOnly(start),
      _dateOnly(end),
    );
  }

  static Future<Map<String, dynamic>> getStationFuelQuantityReport(
      String token, DateTime start, DateTime end) async {
    return DirectReportService.stationFuelQuantities(
      _dateOnly(start),
      _dateOnly(end),
    );
  }

  static Future<Map<String, dynamic>> getSettlementReport(
    String token, {
    required DateTime start,
    required DateTime end,
    String? fuelType,
    String? vehicleNumber,
  }) async {
    return DirectReportService.settlement(
      startDate: _dateOnly(start),
      endDate: _dateOnly(end),
      fuelType: fuelType,
      vehicleNumber: vehicleNumber,
    );
  }

  // ============================================================
  // Card Delivery
  // ============================================================

  static Future<List<Map<String, dynamic>>> listCardDeliveryRecords(
      String token) async {
    return DirectCardDeliveryService.list();
  }

  static Future<Map<String, dynamic>> createCardDeliveryRecord(
      String token, DateTime start, DateTime end) async {
    return DirectCardDeliveryService.create(start, end);
  }

  static Future<Map<String, dynamic>> updateCardDeliveryRecord(
      String token, int id, List<Map<String, dynamic>> items) async {
    return DirectCardDeliveryService.update(id, items);
  }

  static Future<Map<String, dynamic>> addCardDeliveryVehicle(
      String token, int id, String vehicleNumber) async {
    return DirectCardDeliveryService.addVehicle(id, vehicleNumber);
  }

  static Future<Map<String, dynamic>> importCardDeliveryGasVehicles(
      String token, int id, String startDate, String endDate) async {
    return DirectCardDeliveryService.importGasVehicles(
      id,
      startDate,
      endDate,
    );
  }

  static Future<Map<String, dynamic>> deleteCardDeliveryVehicle(
      String token, int id, int itemId) async {
    return DirectCardDeliveryService.deleteVehicle(id, itemId);
  }

  static Future<void> deleteCardDeliveryRecord(
      String token, int id) async {
    return DirectCardDeliveryService.delete(id);
  }

  // ============================================================
  // Helpers
  // ============================================================

  static String _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day)
          .toIso8601String()
          .split('T')
          .first;

  // ============================================================
  // Store
  // ============================================================

  static Future<Map<String, dynamic>> fetchInvoicePrices(
      String token) async {
    return DirectStoreService.fetchInvoicePrices();
  }

  static Future<Map<String, dynamic>> fetchStoreBalances(
      String token) async {
    return DirectStoreService.fetchStoreBalances();
  }

  static Future<List<Map<String, dynamic>>> listInventoryCounts(
      String token) async {
    return DirectStoreService.listInventoryCounts();
  }

  static Future<Map<String, dynamic>> createInventoryCount(
      String token, Map<String, dynamic> payload) async {
    return DirectStoreService.createInventoryCount(payload);
  }

  static Future<void> deleteInventoryCount(
      String token, int countId) async {
    return DirectStoreService.deleteInventoryCount(countId);
  }

  // ============================================================
  // Missions
  // ============================================================

  static Future<Map<String, dynamic>> createMission(
      String token, Map<String, dynamic> payload) async {
    return DirectMissionService.create(payload);
  }

  static Future<List<Map<String, dynamic>>> listMissions(
      String token) async {
    return DirectMissionService.list();
  }

  static Future<Map<String, dynamic>> getMission(
      String token, int missionId) async {
    return DirectMissionService.get(missionId);
  }

  static Future<void> deleteMission(
      String token, int missionId) async {
    return DirectMissionService.delete(missionId);
  }

  static Future<Uint8List> exportMissions(
    String token, {
    DateTime? startDate,
    DateTime? endDate,
    String? vehicleNumber,
  }) async {
    return DirectMissionService.export(
      startDate: startDate,
      endDate: endDate,
      vehicleNumber: vehicleNumber,
    );
  }

  static Future<Map<String, dynamic>> updateMission(
      String token, int missionId, Map<String, dynamic> payload) async {
    return DirectMissionService.update(
      missionId,
      payload,
    );
  }

  static Future<Map<String, dynamic>> addMissionExpense(
      String token, int missionId, Map<String, dynamic> payload) async {
    return DirectMissionService.addExpense(
      missionId,
      payload,
    );
  }

  static Future<Map<String, dynamic>> updateMissionExpense(
      String token,
      int missionId,
      int expenseId,
      Map<String, dynamic> payload) async {
    return DirectMissionService.updateExpense(
      missionId,
      expenseId,
      payload,
    );
  }

  static Future<void> deleteMissionExpense(
      String token, int missionId, int expenseId) async {
    return DirectMissionService.deleteExpense(
      missionId,
      expenseId,
    );
  }

  static Future<Map<String, dynamic>> completeMission(
      String token, int missionId, {bool force = false}) async {
    return DirectMissionService.complete(
      missionId,
      force: force,
    );
  }

  static Future<Map<String, dynamic>> cardTopup(
      String token, Map<String, dynamic> payload) async {
    return DirectMissionService.cardTopup(payload);
  }

  static Future<Map<String, dynamic>> cardDeduct(
      String token, Map<String, dynamic> payload) async {
    return DirectMissionService.cardDeduct(payload);
  }

  // ============================================================
  // Invoices
  // ============================================================

  static Future<List<Map<String, dynamic>>> listAddInvoices(
      String token) async {
    return DirectStoreService.listAddInvoices();
  }

  static Future<Map<String, dynamic>> getAddInvoice(
      String token, int invoiceId) async {
    return DirectStoreService.getAddInvoice(invoiceId);
  }

  static Future<Map<String, dynamic>> createAddInvoice(
      String token, Map<String, dynamic> payload) async {
    return DirectStoreService.createAddInvoice(payload);
  }

  static Future<Map<String, dynamic>> updateAddInvoice(
      String token, int invoiceId, Map<String, dynamic> payload) async {
    return DirectStoreService.updateAddInvoice(
      invoiceId,
      payload,
    );
  }

  static Future<void> deleteAddInvoice(
      String token, int invoiceId) async {
    return DirectStoreService.deleteAddInvoice(invoiceId);
  }

  static Future<Map<String, dynamic>> createInventoryDiscount(
      String token, Map<String, dynamic> payload) async {
    return DirectStoreService.createInventoryDiscount(payload);
  }

  static Future<Map<String, dynamic>> applyPriceChange(
      String token, Map<String, dynamic> payload) async {
    return DirectStoreService.applyPriceChange(payload);
  }

  static Future<List<Map<String, dynamic>>> fetchPriceChangeLogs(
      String token) async {
    return DirectStoreService.fetchInvoicePriceHistory();
  }

  static Future<void> deletePriceChangeLog(
      String token, int logId) async {
    return DirectStoreService.deleteInvoicePriceHistory(logId);
  }

  static Future<Map<String, dynamic>> saveInvoicePrices(
      String token, Map<String, double> prices) async {
    return DirectStoreService.saveInvoicePrices(prices);
  }

  static Future<Map<String, dynamic>> calculateInvoice(
    String token, {
    required String station,
    required String startDate,
    required String endDate,
    required Map<String, double> prices,
  }) async {
    return DirectInvoiceService.calculate(
      station: station,
      startDate: startDate,
      endDate: endDate,
      prices: prices,
    );
  }

  static Future<Map<String, dynamic>> createInvoice(
      String token, Map<String, dynamic> payload) async {
    return DirectInvoiceService.create(payload);
  }

  static Future<List<Map<String, dynamic>>> listInvoices(
    String token, {
    String? station,
    DateTime? date,
    int? month,
    int? year,
    String? invoiceNumber,
  }) async {
    return DirectInvoiceService.list(
      station: station,
      date: date,
      month: month,
      year: year,
      invoiceNumber: invoiceNumber,
    );
  }

  static Future<List<Map<String, dynamic>>> fetchInvoicePriceChangeLogs(
      String token) async {
    return DirectStoreService.fetchInvoicePriceHistory();
  }

  static Future<void> deleteInvoicePriceChangeLog(
      String token, int logId) async {
    return DirectStoreService.deleteInvoicePriceHistory(logId);
  }

  static Future<Map<String, dynamic>> getInvoice(
      String token, int invoiceId) async {
    return DirectInvoiceService.get(invoiceId);
  }

  static Future<Map<String, dynamic>> updateInvoice(
      String token, int invoiceId, Map<String, dynamic> payload) async {
    return DirectInvoiceService.update(
      invoiceId,
      payload,
    );
  }

  static Future<void> deleteInvoice(
      String token, int invoiceId) async {
    return DirectInvoiceService.delete(invoiceId);
  }

  // ============================================================
  // Vehicles
  // ============================================================

  static Future<Vehicle> updateVehicle(
      String token, int id, Map<String, dynamic> vehicleJson) async {
    return DirectVehicleService.update(
      id,
      vehicleJson,
    );
  }

  static Future<void> deleteVehicle(
      String token, int id) async {
    return DirectVehicleService.delete(id);
  }

  // ============================================================
  // Models / User
  // ============================================================

  static Future<List<Map<String, dynamic>>> listModels(
      String token) async {
    return DirectModelConfigService.list();
  }

  static Future<Map<String, dynamic>> getCurrentUser(
      String token) async {
    return DirectUserService.currentUser();
  }

  static Future<void> updateUsername(
      String token, String newUsername) async {
    return DirectUserService.updateUsername(newUsername);
  }

  static Future<void> changePassword(
      String token,
      String currentPassword,
      String newPassword) async {
    return DirectUserService.changePassword(newPassword);
  }

  // ============================================================
  // Sync
  // ============================================================

  static Future<void> manualSync(String token) async {
    // Direct database mode is live; there is no local-to-server sync step.
    return;
  }

  // ============================================================
  // Archives
  // ============================================================

  static Future<List<Map<String, dynamic>>> listArchives(
      String token) async {
    return DirectArchiveService.list();
  }

  static Future<Map<String, dynamic>> previewArchive(
    String token, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return DirectArchiveService.preview(
      startDate,
      endDate,
    );
  }

  static Future<Map<String, dynamic>> createArchive(
    String token, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return DirectArchiveService.create(
      startDate,
      endDate,
    );
  }

  static String _formatArchiveDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, dynamic>> getArchiveStatus(
      String token) async {
    return DirectArchiveService.status();
  }

  static Future<Map<String, dynamic>> cleanupArchivedData(
  String token, {
  DateTime? startDate,
  DateTime? endDate,
  bool confirm = true,
}) async {
  if (startDate == null || endDate == null) {
    throw ArgumentError(
      'يجب تحديد تاريخ بداية ونهاية الأرشيف قبل التنظيف.',
    );
  }

  return DirectArchiveService.cleanup(
    startDate: startDate,
    endDate: endDate,
    confirm: confirm,
  );
}

  static Future<Map<String, dynamic>> loadArchiveTemporarily(
      String token, String filename) async {
    return DirectArchiveService.loadTemporarily(filename);
  }

  static Future<void> clearTemporaryArchive(
      String token) async {
    return DirectArchiveService.clearTemporary();
  }

  static Future<Map<String, dynamic>> getTemporaryArchiveStatus(
      String token) async {
    return DirectArchiveService.temporaryStatus();
  }

  static Future<void> removeTemporaryArchive(
      String token, String filename) async {
    return DirectArchiveService.removeTemporary(filename);
  }

  static Future<String> downloadArchive(
      String token, String filename) async {
    return DirectArchiveService.download(filename);
  }

  static Future<void> deleteArchive(
      String token, String filename) async {
    return DirectArchiveService.delete(filename);
  }
}
