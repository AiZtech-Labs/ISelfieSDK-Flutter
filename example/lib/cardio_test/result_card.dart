import 'package:iselfie_sdk/iselfie_sdk.dart';
import 'package:material_ui/material_ui.dart';

/// The vitals of a completed test. A metric the organization's plan leaves out shows as "—".
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result});

  final CardioResult result;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Heart rate', _format(result.heartRate, 'bpm')),
      ('Blood pressure', result.bloodPressure?.toString() ?? '—'),
      ('SpO2', _format(result.spo2, '%')),
      ('HRV', _format(result.hrv, 'ms')),
      ('Respiratory rate', _format(result.respiratoryRate, 'brpm')),
      ('Test id', result.testId ?? '—'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label),
                    Flexible(child: Text(value, textAlign: TextAlign.end)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _format(int? value, String unit) => value == null ? '—' : '$value $unit';
}
