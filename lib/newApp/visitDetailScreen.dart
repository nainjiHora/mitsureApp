import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mittsure/newApp/bookLoader.dart';
import 'package:mittsure/services/apiService.dart';


class VisitDetailsScreen extends StatefulWidget {
  const VisitDetailsScreen({super.key, required this.visitDetails});

  final Map<String, dynamic> visitDetails;

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  bool _isLoading = true;
  bool _isError = false;
  Map<String, dynamic> _visitData = const {};

  @override
  void initState() {
    super.initState();
    _fetchVisit();
  }

  Future<void> _fetchVisit() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final response = await ApiService.post(
        endpoint: '/visit/fetchVisitById',
        body: {
          'visitId': widget.visitDetails['visitId'],
        },
      );

      if (!mounted) return; // In case the widget was disposed while awaiting.

      if (response != null) {
        final data = response['data'];
        final first = (data is List && data.isNotEmpty) ? data.first : <String, dynamic>{};
        setState(() {
          _visitData = Map<String, dynamic>.from(first as Map);
          _isLoading = false;
          print(_visitData);
          print("data for visit");
        });
      } else {
        throw Exception('Null response');
      }
    } catch (err, st) {
      debugPrint('Error fetching visit: $err\n$st');
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = widget.visitDetails['schoolName'] as String? ??
        widget.visitDetails['DistributorName'] as String? ??
        'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchVisit,
            child: _buildBody(theme),
          ),
          if (_isLoading) const BookPageLoader(),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _CenteredMessage(
            icon: Icons.error_outline,
            message: 'Something went wrong while loading the visit. Pull to retry.',
          ),
        ],
      );
    }

    if (_visitData.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          _CenteredMessage(
            icon: Icons.info_outline,
            message: 'No visit details found.',
          ),
        ],
      );
    }

    final fv = _parseFurtherVisit(_visitData['furtherVisitRequired']);

    // Build a list of fields to render in a standard way.
    final fields = <_VisitField>[
      // _VisitField(
      //   label: 'Visit Start Time',
      //   value: _formatIsoToLocal(_visitData['startTime'] as String?),
      //   icon: Icons.play_arrow,
      // ),
      // _VisitField(
      //   label: 'Visit End Time',
      //   value: _formatIsoToLocal(_visitData['endTime'] as String?),
      //   icon: Icons.stop,
      // ),
      _VisitField(
        label: 'Contact Person',
        value: _visitData['ContactPerson'] as String?,
        icon: Icons.person_2_sharp,
      ),
      _VisitField(
        label: 'Contact Number',
        value: _visitData['PhoneNumber'] as String?,
        icon: Icons.call,
      ),
      _VisitField(
        label: 'Visit Location',
        value: _visitData['start_address'] as String?,
        icon: Icons.location_on_outlined,
      ),
      _VisitField(
        label: 'Visit mode',
        value: _visitData['tag_user']==null||_visitData['tag_user']=="null"?'Individual':'Joint visit',
        icon: Icons.group,
      ),
      _VisitField(
        label: 'Time taken from last point',
        value: (_visitData['time_taken_from_last_visit']).toString() as String?,
        icon: Icons.person,
      ),

       _VisitField(
        label: 'Distance from last point',
        value: (_visitData['distance_from_last_visit']).toString() as String?,
        icon: Icons.person,
      ), _VisitField(
        label: 'Colleague',
        value: _visitData['tag_user'] as String?,
        icon: Icons.person,
      ),
      _VisitField(
        label: 'Visit Done By',
        value: _visitData['u_name'] as String?,
        icon: Icons.person,
      ),
       _VisitField(
        label: 'Visit Purpose',
        value: _visitData['typeName'] as String?,
        icon: Icons.category_outlined,
      ),
      _VisitField(
        label: 'Work Done',
        value: _visitData['workDoneName'] as String?,
        icon: Icons.build_outlined,
      ),
      _VisitField(
        label: 'Visit Outcome',
        value: _visitData['visitOutcomeName'] as String?,
        icon: Icons.flag_outlined,
      ),
      _VisitField(
        label: 'Next Step',
        value: _visitData['nextStepName'] as String?,
        icon: Icons.trending_up,
      ),
     _VisitField(
        label: 'Follow Up Date',
        value: _formatIsoToLocal(_visitData['followUpDate']),
        icon: Icons.calendar_month,
      ),
      _VisitField(
        label: 'Follow Up Remark',
        value: _visitData['followUpRemark'],
        icon: Icons.calendar_month,
      ),
      
      _VisitField(
        label: 'Further Visit Required',
        value: fv.visitRequired == null
            ? 'N/A'
            : fv.visitRequired!
                ? 'Yes'
                : 'No',
        icon: Icons.repeat_on_outlined,
      ),
      _VisitField(
        label: 'Further Visit Remark',
        value: fv.reason,
        icon: Icons.notes_outlined,
      ),
      
      _VisitField(label: "Ho Actionable Items", value: _visitData['ho_need_remark']??"N/A", icon: Icons.person_2_sharp),
      _VisitField(
        label: 'Visit Start Remark',
        value: _visitData['extra'] as String?,
        icon: Icons.comment_outlined,
      ),
      _VisitField(
        label: 'Visit End Remark',
        value: _visitData['visitEndRemark'] as String?,
        icon: Icons.comment_outlined,
      ),
      _VisitField(
        label: 'Status',
        value: _visitData['statusTypeName'] as String?,
        icon: Icons.check_circle_outlined,
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(
          start: _visitData['startTime'] as String?,
          end: _visitData['endTime'] as String?,
          meetingStart:_visitData['start_time_meeting'] as String?,
          meetingEnd:_visitData['end_time_meeting'] as String?,

        ),
        const SizedBox(height: 16),
        _InfoCard(fields: fields),
      ],
    );
  }

  /// Format an ISO8601 UTC string into local time.
  String _formatIsoToLocal(String? isoDateStr, {String format = 'dd-MM-yyyy'}) {
    if (isoDateStr == null || isoDateStr.isEmpty) return 'N/A';
    try {
      final utcDate = DateTime.parse(isoDateStr);
      final localDate = utcDate.toLocal();
      return DateFormat(format).format(localDate);
    } catch (_) {
      return 'Invalid date';
    }
  }

  _FurtherVisit _parseFurtherVisit(dynamic raw) {
    try {
      if (raw == null) return const _FurtherVisit();
      final obj = raw is String ? jsonDecode(raw) : raw;
      if (obj is Map) {
        final visitRequired = obj['visit_required'];
        final reason = obj['reason']?.toString();
        return _FurtherVisit(
          visitRequired: visitRequired is bool
              ? visitRequired
              : (visitRequired is num ? visitRequired != 0 : null),
          reason: (reason != null && reason.trim().isNotEmpty) ? reason : null,
        );
      }
      return const _FurtherVisit();
    } catch (e) {
      debugPrint('Error parsing furtherVisitRequired: $e');
      return const _FurtherVisit();
    }
  }
}

/// Small data holder for further visit parsing.
class _FurtherVisit {
  const _FurtherVisit({this.visitRequired, this.reason});
  final bool? visitRequired;
  final String? reason;
}

/// Descriptor for a field shown in the InfoCard.
class _VisitField {
  const _VisitField({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String? value;
  final IconData icon;
}

/// A top summary card highlighting start & end times.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.start,
    required this.end,
    required this.meetingStart,
    required this.meetingEnd
  });

  final String? end;
  final String? start;
  final String? meetingStart;
  final String? meetingEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startStr = _format(start);
    final endStr = _format(end);
    final endmeet = _format(meetingEnd);
    final strmeet = _format(meetingStart);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TimeBlock(
              label: 'Visit Start',
              time: startStr,
              icon: Icons.play_arrow,
              color: theme.colorScheme.primary,
            ),
            Container(width: 1, height: 40, color: theme.dividerColor.withOpacity(.4)),
            _TimeBlock(
              label: 'Meeting ',
              time: strmeet,
              icon: Icons.timer,
              color: theme.colorScheme.primary,
            ),
            Container(width: 1, height: 40, color: theme.dividerColor.withOpacity(.4)),
            _TimeBlock(
              label: 'Meeting End',
              time: endmeet,
              icon: Icons.lock_clock,
              color: theme.colorScheme.primary,
            ),
            Container(width: 1, height: 40, color: theme.dividerColor.withOpacity(.4)),
            _TimeBlock(
              label: 'Visit End',
              time: endStr,
              icon: Icons.timer,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  static String _format(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd-MM-yyyy\nhh:mm a').format(dt);
    } catch (_) {
      return 'Invalid date';
    }
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String label;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card that renders a vertical list of visit fields.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.fields});
  final List<_VisitField> fields;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (int i = 0; i < fields.length; i++) ...[
              _InfoRow(field: fields[i]),
              if (i < fields.length - 1)
                Divider(height: 1, thickness: .5, color: theme.dividerColor.withOpacity(.4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.field});
  final _VisitField field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (field.value == null || field.value!.trim().isEmpty) ? 'N/A' : field.value!.trim();
    return ListTile(
      leading: Icon(field.icon, color: theme.colorScheme.primary),
      title: Text(field.label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(value, style: theme.textTheme.bodyMedium),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Centered placeholder message widget.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
