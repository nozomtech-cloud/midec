import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

void main() {
  runApp(const MedicationApp());
}

class MedicationApp extends StatelessWidget {
  const MedicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منبه الأدوية الذكي',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const MedicationHomeScreen(),
    );
  }
}

class MedicationHomeScreen extends StatefulWidget {
  const MedicationHomeScreen({super.key});

  @override
  State<MedicationHomeScreen> createState() => _MedicationHomeScreenState();
}

class _MedicationHomeScreenState extends State<MedicationHomeScreen> {
  final List<Map<String, dynamic>> _medications = [
    {
      'id': 1,
      'name': 'بانادول',
      'date': '2026-06-01',
      'time': '08:00',
      'dose': 'قرص واحد',
      'alerted15': false,
      'alertedExact': false,
    },
    {
      'id': 2,
      'name': 'فيتازيد',
      'date': '2026-06-01',
      'time': '14:00',
      'dose': 'ملعقة',
      'alerted15': false,
      'alertedExact': false,
    },
  ];

  Timer? _alarmTimer;
  bool _isAlarmActive = false;

  @override
  void initState() {
    super.initState();
    _startAutomaticAlarmSystem();
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    super.dispose();
  }

  void _startAutomaticAlarmSystem() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final currentDateStr = DateFormat('yyyy-MM-dd').format(now);

      for (var med in _medications) {
        if (med['date'] == currentDateStr) {
          try {
            final medParts = med['time'].split(':');
            final int medHour = int.parse(medParts[0]);
            final int medMinute = int.parse(medParts[1]);
            
            final int medTotalMinutes = medHour * 60 + medMinute;
            final int currentTotalMinutes = now.hour * 60 + now.minute;
            final int diffMinutes = medTotalMinutes - currentTotalMinutes;

            if (diffMinutes == 15 && med['alerted15'] != true) {
              med['alerted15'] = true;
              if (!_isAlarmActive) {
                _triggerEmergencyAlarm(med, '15min');
              }
            }

            if (diffMinutes == 0 && now.second == 0 && med['alertedExact'] != true) {
              med['alertedExact'] = true;
              if (!_isAlarmActive) {
                _triggerEmergencyAlarm(med, 'exact');
              }
            }
          } catch (e) {
            // تجاهل أي خطأ تنسيقي لتفادي توقف المحرك
          }
        }
      }
    });
  }

  void _triggerEmergencyAlarm(Map<String, dynamic> med, String alertType) {
    _isAlarmActive = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.red[900],
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 10),
                Text(
                  alertType == '15min' ? '⚠️ تنبيه استباقي (قبل بربع ساعة)!' : '🚨 موعد الدواء الآن (حرج وإلزامي)!',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            content: Text(
              alertType == '15min'
                  ? 'تنبيه آلي: موعد دواء (${med['name']}) خلال 15 دقيقة (${med['time']}). استعد لتناول جرعة: ${med['dose']}'
                  : 'حان الآن موعد الدواء الإلزامي بدقة!\n\nاسم الدواء: ${med['name']}\nالجرعة: ${med['dose']}\n\nلن يتوقف هذا التنبيه ويغلق التطبيق إلا بالضغط على زر "تم" أدناه!',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    _isAlarmActive = false;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تأكيد تناول دواء ${med['name']} بنجاح')),
                    );
                  },
                  child: const Text(
                    'تم (أخذت الدواء)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMedicationDialog({Map<String, dynamic>? existingMed, int? index}) {
    String name = existingMed != null ? existingMed['name'] : '';
    String date = existingMed != null ? existingMed['date'] : DateFormat('yyyy-MM-dd').format(DateTime.now());
    String time = existingMed != null ? existingMed['time'] : '08:00';
    String dose = existingMed != null ? existingMed['dose'] : 'قرص واحد';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existingMed == null ? 'إضافة دواء جديد' : 'تعديل بيانات الدواء'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: TextEditingController(text: name),
                  decoration: const InputDecoration(labelText: 'اسم الدواء'),
                  onChanged: (val) => name = val,
                ),
                TextField(
                  controller: TextEditingController(text: date),
                  decoration: const InputDecoration(labelText: 'التاريخ (YYYY-MM-DD)'),
                  onChanged: (val) => date = val,
                ),
                TextField(
                  controller: TextEditingController(text: time),
                  decoration: const InputDecoration(labelText: 'الساعة (صيغة 24 ساعة مثل: 08:00 أو 14:30)'),
                  onChanged: (val) => time = val,
                ),
                TextField(
                  controller: TextEditingController(text: dose),
                  decoration: const InputDecoration(labelText: 'الجرعة'),
                  onChanged: (val) => dose = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  setState(() {
                    if (existingMed == null) {
                      _medications.add({
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'name': name,
                        'date': date,
                        'time': time,
                        'dose': dose,
                        'alerted15': false,
                        'alertedExact': false,
                      });
                    } else {
                      _medications[index!] = {
                        'id': existingMed['id'],
                        'name': name,
                        'date': date,
                        'time': time,
                        'dose': dose,
                        'alerted15': false,
                        'alertedExact': false,
                      };
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ الجدول وتفعيل المنبه الآلي بنجاح')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف الدواء وإلغاء جدولته')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول ومنبه الأدوية الأسبوعي الذكي'),
        centerTitle: true,
      ),
      body: _medications.isEmpty
          ? const Center(
              child: Text(
                'لا توجد أدوية مضافة حالياً',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _medications.length,
              itemBuilder: (context, index) {
                final med = _medications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.medication, color: Colors.teal, size: 40),
                    title: Text(
                      med['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'التاريخ: ${med['date']}  |  الوقت: ${med['time']}\nالجرعة: ${med['dose']}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showMedicationDialog(existingMed: med, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMedication(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMedicationDialog(),
        child: const Icon(Icons.add),
        tooltip: 'إضافة دواء جديد',
      ),
    );
  }
}
