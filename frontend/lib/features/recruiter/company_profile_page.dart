import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/theme/glass_tokens.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/list_parts.dart';
import '../../core/widgets/page_parts.dart';
import 'recruiter_parts.dart';
import 'recruiter_sample.dart';

// company details, verification status and edit form
class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key, this.store});

  final RecruiterSample? store;

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  RecruiterSample get _s => widget.store ?? recruiterSample;
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          kicker: 'Recruiter',
          title: 'Company profile',
          subtitle:
              'Job seekers see these details on every job you post. The Admin checks them before your jobs go live.',
          trailing: const GlassChip(label: 'Sample data'),
        ),
        const SizedBox(height: Gaps.section),
        if (_editing)
          _CompanyForm(
            company: _s.company,
            onCancel: () => setState(() => _editing = false),
            onSaved: () {
              _s.saveCompany();
              setState(() => _editing = false);
              showDone(context, 'Company profile saved.');
            },
          )
        else
          _CompanyView(company: _s.company, onEdit: () => setState(() => _editing = true)),
      ],
    );
  }
}

class _CompanyView extends StatelessWidget {
  const _CompanyView({required this.company, required this.onEdit});

  final Company company;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final t = GlassTokens.of(context);
    final c = company;
    final rows = [
      ('Industry', c.industry),
      ('Company size', c.size),
      ('Office address', c.address),
      ('Website', c.website),
      ('Contact email', c.email),
      ('Work arrangement', c.workArrangement),
      ('Benefits', c.benefits.isEmpty ? 'None listed' : c.benefits.join(', ')),
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.ink, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  c.name.isEmpty ? '?' : c.name[0],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: t.inkText),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: TwoLines(c.name, c.industry)),
              GlassChip(
                label: c.verified ? 'Verified' : 'Waiting for Admin',
                color: c.verified ? t.success : t.warning,
              ),
            ],
          ),
          if (c.verified) ...[
            const SizedBox(height: 8),
            Text(
              'Proof document approved by the Admin on ${shortDate(c.verifiedOn)}.',
              style: TextStyle(fontSize: 14, color: t.textSub),
            ),
          ],
          const SizedBox(height: 20),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.textSub),
                    ),
                  ),
                  Expanded(
                    child: Text(value, style: TextStyle(fontSize: 15, color: t.text)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.row, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (heading, body)) in [
                  ('About the company', c.about),
                  ('Culture and values', c.culture),
                  ('Mission and vision', c.vision),
                ].indexed) ...[
                  if (i > 0) const SizedBox(height: 14),
                  Text(
                    heading,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(fontSize: 15, height: 1.5, color: t.textSub)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }
}

class _CompanyForm extends StatefulWidget {
  const _CompanyForm({required this.company, required this.onCancel, required this.onSaved});

  final Company company;
  final VoidCallback onCancel;
  final VoidCallback onSaved;

  @override
  State<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<_CompanyForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.company.name);
  late final _address = TextEditingController(text: widget.company.address);
  late final _website = TextEditingController(text: widget.company.website);
  late final _email = TextEditingController(text: widget.company.email);
  late final _about = TextEditingController(text: widget.company.about);
  late final _culture = TextEditingController(text: widget.company.culture);
  late final _vision = TextEditingController(text: widget.company.vision);
  late String? _logo = widget.company.logo;
  late String? _photos = widget.company.photos;
  late String _industry = widget.company.industry;
  late String _size = widget.company.size;
  late String _arrangement = widget.company.workArrangement;
  late final Set<String> _benefits = {...widget.company.benefits};

  @override
  void dispose() {
    for (final c in [_name, _address, _website, _email, _about, _culture, _vision]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Fill this in.' : null;

  void _save() {
    if (!_form.currentState!.validate()) return;
    widget.company
      ..name = _name.text.trim()
      ..address = _address.text.trim()
      ..website = _website.text.trim()
      ..email = _email.text.trim()
      ..about = _about.text.trim()
      ..culture = _culture.text.trim()
      ..vision = _vision.text.trim()
      ..logo = _logo
      ..photos = _photos
      ..industry = _industry
      ..size = _size
      ..workArrangement = _arrangement
      ..benefits = _benefits;
    widget.onSaved();
  }

  Future<void> _pick(bool many, ValueChanged<String> onPicked) async {
    final picked = many
        ? await FilePicker.pickFiles(type: FileType.image)
        : [?await FilePicker.pickFile(type: FileType.image)];
    if (picked.isEmpty) return;
    setState(() => onPicked(picked.map((f) => f.name).join(', ')));
  }

  Widget _upload(String label, String? chosen, bool many, ValueChanged<String> onPicked) {
    final t = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        OutlinedButton.icon(
          onPressed: () => _pick(many, onPicked),
          icon: const Icon(Icons.upload_outlined, size: 18),
          label: Text(many ? 'Choose photos' : 'Choose logo'),
        ),
        const SizedBox(height: 6),
        Text(chosen ?? 'No file chosen', style: TextStyle(fontSize: 14, color: t.textSub)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Edit company details'),
            FieldPair(
              TextFormField(
                key: const Key('company-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Company name'),
                validator: _required,
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _industry,
                decoration: const InputDecoration(labelText: 'Industry'),
                items: [for (final i in industries) DropdownMenuItem(value: i, child: Text(i))],
                onChanged: (v) => _industry = v!,
              ),
            ),
            const SizedBox(height: 16),
            FieldPair(
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _size,
                decoration: const InputDecoration(labelText: 'Company size'),
                items: [for (final s in companySizes) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (v) => _size = v!,
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Office address'),
                validator: _required,
              ),
            ),
            const SizedBox(height: 16),
            FieldPair(
              TextFormField(
                controller: _website,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Contact email for applicants'),
                validator: (v) => (v ?? '').contains('@') ? null : 'Enter an email address.',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _about,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'About the company (2–3 sentences)'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            FieldPair(
              TextFormField(
                controller: _culture,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Culture and values'),
              ),
              TextFormField(
                controller: _vision,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Mission and vision'),
              ),
            ),
            const SizedBox(height: 20),
            FieldPair(
              _upload('Logo (square image, up to 2 MB)', _logo, false, (v) => _logo = v),
              _upload('Office or workspace photos', _photos, true, (v) => _photos = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _arrangement,
                decoration: const InputDecoration(labelText: 'Work arrangement'),
                items: [for (final w in workArrangements) DropdownMenuItem(value: w, child: Text(w))],
                onChanged: (v) => _arrangement = v!,
              ),
            ),
            const SizedBox(height: 20),
            const FieldLabel('Benefits'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in allBenefits)
                  FilterChip(
                    label: Text(b),
                    selected: _benefits.contains(b),
                    onSelected: (on) => setState(() => on ? _benefits.add(b) : _benefits.remove(b)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                FilledButton(onPressed: _save, child: const Text('Save profile')),
                const SizedBox(width: 12),
                OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
