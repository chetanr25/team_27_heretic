import 'package:flutter/material.dart';

class PatientDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    final data = patientData['data'];
    final patient = data['patient'];
    final emergencyContact = data['emergencyContact'];
    final insuranceInfo = data['insuranceInfo'];

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Basic Information', [
              _buildInfoRow('Name', patient['name']),
              _buildInfoRow('Email', patient['email']),
              _buildInfoRow('Blood Type', data['bloodType']),
              _buildInfoRow('Last Updated', _formatDate(data['lastUpdated'])),
            ]),
            const SizedBox(height: 16),
            _buildSection('Medical Information', [
              if (data['conditions'].isNotEmpty)
                _buildInfoRow(
                  'Conditions',
                  (data['conditions'] as List).join(', '),
                ),
              if (data['allergies'].isNotEmpty)
                _buildInfoRow(
                  'Allergies',
                  (data['allergies'] as List).join(', '),
                ),
            ]),
            const SizedBox(height: 16),
            if (data['medications'].isNotEmpty) ...[
              _buildSection(
                'Medications',
                (data['medications'] as List).map((medication) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Name', medication['name']),
                            _buildInfoRow('Dosage', medication['dosage']),
                            _buildInfoRow('Frequency', medication['frequency']),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            _buildSection('Emergency Contact', [
              _buildInfoRow('Name', emergencyContact['name']),
              _buildInfoRow('Relationship', emergencyContact['relationship']),
              _buildInfoRow('Phone', emergencyContact['phone']),
            ]),
            const SizedBox(height: 16),
            _buildSection('Insurance Information', [
              _buildInfoRow(
                'Provider',
                insuranceInfo['provider'].toString().isEmpty
                    ? 'Not provided'
                    : insuranceInfo['provider'],
              ),
              _buildInfoRow(
                'Policy Number',
                insuranceInfo['policyNumber'].toString().isEmpty
                    ? 'Not provided'
                    : insuranceInfo['policyNumber'],
              ),
              _buildInfoRow(
                'Group Number',
                insuranceInfo['groupNumber'].toString().isEmpty
                    ? 'Not provided'
                    : insuranceInfo['groupNumber'],
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }
}
