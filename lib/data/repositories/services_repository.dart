import '../models/service_summary.dart';
import '../services/api_service.dart';
import '../../core/errors/exceptions.dart';

class ServicesRepository {
  final ApiService _apiService;

  ServicesRepository(this._apiService);

  Future<List<ServiceSummary>> listServices({String? timeRange}) async {
    try {
      return await _apiService.getServices(timeRange: timeRange);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch services: ${e.toString()}');
    }
  }

  Future<ServiceDetail> getService(String name, {String? timeRange}) async {
    try {
      return await _apiService.getServiceDetail(name, timeRange: timeRange);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch service detail: ${e.toString()}');
    }
  }
}
