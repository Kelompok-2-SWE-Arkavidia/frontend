import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Dashboard stats states
enum DashboardStatsState { initial, loading, loaded, error }

// Dashboard stats data class
class DashboardStatsData {
  final DashboardStats stats;
  final DashboardStatsState state;
  final String? errorMessage;

  DashboardStatsData({
    required this.stats,
    required this.state,
    this.errorMessage,
  });

  DashboardStatsData copyWith({
    DashboardStats? stats,
    DashboardStatsState? state,
    String? errorMessage,
  }) {
    return DashboardStatsData(
      stats: stats ?? this.stats,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Dashboard stats notifier
class DashboardStatsNotifier extends StateNotifier<DashboardStatsData> {
  final ApiService apiService;

  DashboardStatsNotifier(this.apiService)
    : super(
        DashboardStatsData(
          stats: DashboardStats.empty(),
          state: DashboardStatsState.initial,
        ),
      );

  Future<void> fetchDashboardStats() async {
    try {
      state = state.copyWith(state: DashboardStatsState.loading);

      final response = await apiService.getDashboardStats();

      if (response['success'] == true) {
        final data = response['data'];
        if (data != null) {
          final stats = DashboardStats.fromJson(data);
          state = state.copyWith(
            stats: stats,
            state: DashboardStatsState.loaded,
          );
          debugPrint(
            '📊 Dashboard stats loaded: ${stats.totalItems} total items',
          );
        } else {
          state = state.copyWith(
            state: DashboardStatsState.error,
            errorMessage: 'Data statistik tidak ditemukan',
          );
        }
      } else if (response.containsKey('unauthorized') &&
          response['unauthorized'] == true) {
        state = state.copyWith(
          state: DashboardStatsState.error,
          errorMessage: 'Sesi telah berakhir. Silakan login kembali.',
        );
      } else {
        state = state.copyWith(
          state: DashboardStatsState.error,
          errorMessage: response['message'] ?? 'Failed to load dashboard stats',
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: DashboardStatsState.error,
        errorMessage: 'Network error: $e',
      );
      debugPrint('❌ Error fetching dashboard stats: $e');
    }
  }

  void resetState() {
    state = DashboardStatsData(
      stats: DashboardStats.empty(),
      state: DashboardStatsState.initial,
    );
  }
}

// Provider for the ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider for dashboard stats
final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, DashboardStatsData>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return DashboardStatsNotifier(apiService);
    });
