import 'position_sample.dart';

enum WorkoutState { idle, running, paused, ended }

class WorkoutSession {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final WorkoutState state;
  final int durationSeconds;
  final double distanceMeters;
  final double? avgPaceSecondsPerKm;
  final double caloriesEstimate;
  final bool ghostMode;
  final String source;
  final String? title;
  final String? notes;
  final List<PositionSample> points;
  final bool isLoopClosed;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.state = WorkoutState.idle,
    this.durationSeconds = 0,
    this.distanceMeters = 0.0,
    this.avgPaceSecondsPerKm,
    this.caloriesEstimate = 0.0,
    this.ghostMode = false,
    this.source = 'phoneGps',
    this.title,
    this.notes,
    List<PositionSample>? points,
    this.isLoopClosed = false,
  }) : points = List.unmodifiable(points ?? const []);

  Duration get elapsed => Duration(seconds: durationSeconds);

  List<PositionSample> get route => points;

  WorkoutSession copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    WorkoutState? state,
    int? durationSeconds,
    double? distanceMeters,
    double? avgPaceSecondsPerKm,
    double? caloriesEstimate,
    bool? ghostMode,
    String? title,
    String? notes,
    List<PositionSample>? points,
    bool? isLoopClosed,
  }) {
    return WorkoutSession(
      id: id,
      userId: userId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      state: state ?? this.state,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgPaceSecondsPerKm: avgPaceSecondsPerKm ?? this.avgPaceSecondsPerKm,
      caloriesEstimate: caloriesEstimate ?? this.caloriesEstimate,
      ghostMode: ghostMode ?? this.ghostMode,
      source: source,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      points: points ?? this.points,
      isLoopClosed: isLoopClosed ?? this.isLoopClosed,
    );
  }
}
