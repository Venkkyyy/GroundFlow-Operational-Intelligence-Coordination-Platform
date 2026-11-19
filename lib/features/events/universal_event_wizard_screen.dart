import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/models/universal_event_model.dart';
import '../../core/state/ground_flow_realtime_store.dart';
import '../../core/services/event_email_service.dart';

class UniversalEventWizardScreen extends StatefulWidget {
  final VoidCallback onEventCreated;
  const UniversalEventWizardScreen({super.key, required this.onEventCreated});

  @override
  State<UniversalEventWizardScreen> createState() => _UniversalEventWizardScreenState();
}

class _UniversalEventWizardScreenState extends State<UniversalEventWizardScreen> {
  int _currentStep = 0;
  static const int _totalSteps = 7;

  // STEP 1: Foundation & Template
  DepartmentTemplate _selectedTemplate = DepartmentTemplate.allTemplates[4]; // Default: Operations
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _shortNameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool _obscurePassword = true;
  EventCategory _category = EventCategory.conference;
  EventPriority _priority = EventPriority.high;
  EventVisibility _visibility = EventVisibility.organization;

  // STEP 2: Date & Time
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 8));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isAllDay = false;
  int _setupDuration = 2;
  int _breakdownDuration = 2;

  // STEP 3: Venue & Hybrid
  LocationMode _locationMode = LocationMode.physical;
  final TextEditingController _venueNameCtrl = TextEditingController(text: 'MIT-WPU Central Arena');
  final TextEditingController _addressCtrl = TextEditingController(text: 'Kothrud Campus, Paud Road');
  final TextEditingController _cityCtrl = TextEditingController(text: 'Pune');
  final TextEditingController _capacityCtrl = TextEditingController(text: '500');
  final TextEditingController _virtualUrlCtrl = TextEditingController();
  final List<String> _selectedFacilities = ['Wi-Fi', 'Audio System', 'Projector', 'Power Backup', 'Seating', 'Security'];

  // STEP 4: Department & Team Ownership
  String _primaryDept = 'Operations';
  final TextEditingController _ownerEmailCtrl = TextEditingController();
  final TextEditingController _headEmailCtrl = TextEditingController();
  final TextEditingController _coordEmailCtrl = TextEditingController();

  // STEP 5: Role-Segregated Headcount & Budget
  final TextEditingController _totalAttendanceCtrl = TextEditingController(text: '350');
  final TextEditingController _vipCountCtrl = TextEditingController(text: '10');
  final TextEditingController _volunteersCountCtrl = TextEditingController(text: '45');
  final TextEditingController _speakersCountCtrl = TextEditingController(text: '6');
  final TextEditingController _estimatedBudgetCtrl = TextEditingController(text: '75000');
  final TextEditingController _costCenterCtrl = TextEditingController(text: 'CC-OPS-2026');

  // STEP 6: Department-Specific Dynamic Fields
  final Map<String, TextEditingController> _dynamicFieldControllers = {};

  // Validation errors
  String? _stepError;

  @override
  void initState() {
    super.initState();
    final store = GroundFlowRealtimeStore();
    _ownerEmailCtrl.text = store.userEmail;
    _headEmailCtrl.text = store.userEmail;
    _coordEmailCtrl.text = store.userEmail;
    _codeCtrl.text = 'EVT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    _applyTemplateDefaults(_selectedTemplate);
  }

  void _applyTemplateDefaults(DepartmentTemplate template) {
    _primaryDept = template.defaultPrimaryDept;
    _category = template.defaultCategory;

    // Initialize dynamic controllers
    _dynamicFieldControllers.clear();
    template.dynamicFields.forEach((key, val) {
      _dynamicFieldControllers[key] = TextEditingController(text: val.toString());
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shortNameCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _descCtrl.dispose();
    _venueNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _capacityCtrl.dispose();
    _virtualUrlCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _headEmailCtrl.dispose();
    _coordEmailCtrl.dispose();
    _totalAttendanceCtrl.dispose();
    _vipCountCtrl.dispose();
    _volunteersCountCtrl.dispose();
    _speakersCountCtrl.dispose();
    _estimatedBudgetCtrl.dispose();
    _costCenterCtrl.dispose();
    for (var c in _dynamicFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    setState(() => _stepError = null);

    // Validation per step
    if (_currentStep == 0) {
      if (_titleCtrl.text.trim().isEmpty) {
        setState(() => _stepError = 'Please enter an Event Title.');
        return;
      }
      if (_codeCtrl.text.trim().isEmpty) {
        setState(() => _stepError = 'Please provide an Event Code.');
        return;
      }
      if (_passwordCtrl.text.trim().isEmpty) {
        setState(() => _stepError = 'Please set an Event Password / Security Passcode.');
        return;
      }
    } else if (_currentStep == 2) {
      if (_locationMode != LocationMode.online && _venueNameCtrl.text.trim().isEmpty) {
        setState(() => _stepError = 'Please enter a Venue Name.');
        return;
      }
      if (_locationMode != LocationMode.physical && _virtualUrlCtrl.text.trim().isEmpty) {
        setState(() => _stepError = 'Please provide a Virtual Meeting URL.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finalizeAndSaveEvent();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _stepError = null;
      });
    }
  }

  void _finalizeAndSaveEvent({bool asDraft = false}) {
    final store = GroundFlowRealtimeStore();

    // Collect dynamic fields
    final Map<String, dynamic> customFields = {};
    _dynamicFieldControllers.forEach((k, v) {
      customFields[k] = v.text.trim();
    });

    final universalEvent = UniversalEvent(
      code: _codeCtrl.text.trim().toUpperCase(),
      title: _titleCtrl.text.trim(),
      shortName: _shortNameCtrl.text.trim().isEmpty ? _codeCtrl.text.trim() : _shortNameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? '${_titleCtrl.text.trim()} campus operational lifecycle' : _descCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      category: _category,
      priority: _priority,
      status: asDraft ? EventStatus.draft : EventStatus.active,
      visibility: _visibility,
      lifecycle: asDraft ? EventLifecycleState.draft : EventLifecycleState.published,
      templateId: _selectedTemplate.id,
      createdBy: store.userEmail,
      createdAt: DateTime.now(),
      tags: [_primaryDept, _category.displayName, _locationMode.displayName],
      schedule: ScheduleInfo(
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        isAllDay: _isAllDay,
        isMultiDay: _startDate.year != _endDate.year || _startDate.month != _endDate.month || _startDate.day != _endDate.day,
        setupDurationHours: _setupDuration,
        breakdownDurationHours: _breakdownDuration,
      ),
      venue: VenueInfo(
        locationMode: _locationMode,
        venueName: _venueNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        totalCapacity: int.tryParse(_capacityCtrl.text.trim()) ?? 500,
        facilities: _selectedFacilities,
        virtualMeetingUrl: _virtualUrlCtrl.text.trim(),
      ),
      ownership: DepartmentOwnership(
        primaryDepartment: _primaryDept,
        organizingDepartment: _primaryDept,
        eventOwnerEmail: _ownerEmailCtrl.text.trim(),
        departmentHeadEmail: _headEmailCtrl.text.trim(),
        coordinatorEmail: _coordEmailCtrl.text.trim(),
        participatingDepartments: _selectedTemplate.participatingDepartments,
      ),
      headcount: HeadcountBreakdown(
        expectedTotalAttendance: int.tryParse(_totalAttendanceCtrl.text.trim()) ?? 350,
        vipGuests: int.tryParse(_vipCountCtrl.text.trim()) ?? 10,
        volunteers: int.tryParse(_volunteersCountCtrl.text.trim()) ?? 45,
        speakers: int.tryParse(_speakersCountCtrl.text.trim()) ?? 6,
      ),
      budget: BudgetInfo(
        estimatedBudget: double.tryParse(_estimatedBudgetCtrl.text.trim()) ?? 75000.0,
        approvedBudget: double.tryParse(_estimatedBudgetCtrl.text.trim()) ?? 75000.0,
        costCenter: _costCenterCtrl.text.trim(),
        fundingDepartment: _primaryDept,
      ),
      safety: const SafetyEmergencyConfig(),
      customDepartmentFields: customFields,
      automatedTasks: _selectedTemplate.defaultTasks,
    );

    // Save event to store and Cloud Firestore
    store.createEvent(
      title: universalEvent.title,
      venue: universalEvent.venue.venueName,
      code: universalEvent.code,
      password: _passwordCtrl.text.trim(),
      department: universalEvent.ownership.primaryDepartment,
      additionalData: universalEvent.toJson(),
    );

    widget.onEventCreated();
    final conf = store.latestOwnerConfirmation;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Event "${universalEvent.title}" initialized! Pass: VIP-${universalEvent.code}-OWNER'),
        backgroundColor: GlassTheme.accentEmerald,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OPEN EMAIL APP',
          textColor: Colors.black,
          backgroundColor: Colors.white,
          onPressed: () {
            if (conf != null) {
              EventEmailService().launchEmailApp(conf);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0C0E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Universal Event Automation',
              style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              'Step ${_currentStep + 1} of $_totalSteps: ${_getStepTitle(_currentStep)}',
              style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.accentSky, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: GlassTheme.chrome),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: const Color(0xFF1E1E24),
              valueColor: const AlwaysStoppedAnimation<Color>(GlassTheme.accentSky),
              minHeight: 3,
            ),

            if (_stepError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF3B1215),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: GlassTheme.statusRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _stepError!,
                        style: GoogleFonts.roboto(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: _buildCurrentStepView(),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F13),
                border: Border(top: BorderSide(color: GlassTheme.border)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: GlassTheme.white,
                            side: const BorderSide(color: GlassTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: Text('Previous', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600)),
                          onPressed: _prevStep,
                        )
                      else
                        const SizedBox.shrink(),
                      if (_currentStep == _totalSteps - 1) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GlassTheme.mutedSilver,
                                side: const BorderSide(color: GlassTheme.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              icon: const Icon(Icons.drafts_outlined, size: 14),
                              label: Text('Draft', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600)),
                              onPressed: () => _finalizeAndSaveEvent(asDraft: true),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GlassTheme.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.rocket_launch_rounded, size: 15),
                              label: Text('Publish', style: GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              onPressed: () => _finalizeAndSaveEvent(asDraft: false),
                            ),
                          ],
                        ),
                      ] else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: Text('Continue', style: GoogleFonts.roboto(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          onPressed: _nextStep,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Department Template & Foundation';
      case 1:
        return 'Schedule & Agenda Buffer';
      case 2:
        return 'Venue, Location & Hybrid Mode';
      case 3:
        return 'Department Ownership & Stakeholders';
      case 4:
        return 'Headcount Breakdown & Budget';
      case 5:
        return 'Department Dynamic Parameters';
      case 6:
        return 'Automation Engine & Review';
      default:
        return 'Configuration';
    }
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Foundation();
      case 1:
        return _buildStep2Schedule();
      case 2:
        return _buildStep3Venue();
      case 3:
        return _buildStep4Ownership();
      case 4:
        return _buildStep5HeadcountBudget();
      case 5:
        return _buildStep6DynamicFields();
      case 6:
        return _buildStep7AutomationReview();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Foundation & Template
  Widget _buildStep1Foundation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Department Template',
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Customizes mandatory fields, seeded workflows, and automation rules for this operational unit.',
          style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 12),

        // Horizontal Template Cards
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DepartmentTemplate.allTemplates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final t = DepartmentTemplate.allTemplates[i];
              final isSelected = t.id == _selectedTemplate.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTemplate = t;
                    _applyTemplateDefaults(t);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1B1B24) : GlassTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? GlassTheme.accentSky : GlassTheme.border, width: isSelected ? 1.5 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            _getIconData(t.icon),
                            color: isSelected ? GlassTheme.accentSky : GlassTheme.chrome,
                            size: 20,
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: GlassTheme.accentSky, size: 16),
                        ],
                      ),
                      Text(
                        t.name,
                        style: GoogleFonts.roboto(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        t.description,
                        style: GoogleFonts.roboto(fontSize: 10.5, color: GlassTheme.mutedSilver),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 22),
        const Divider(color: GlassTheme.border),
        const SizedBox(height: 16),

        _inputField(label: 'Event Title *', controller: _titleCtrl, hint: 'e.g. Annual Global Engineering Summit 2026'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _inputField(
                label: 'Event Code / Reference ID *',
                controller: _codeCtrl,
                hint: 'e.g. SUMMIT-2026',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                label: 'Event Password / Passcode *',
                controller: _passwordCtrl,
                hint: 'e.g. Pass@123',
                isPassword: true,
                obscure: _obscurePassword,
                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _inputField(label: 'Short Name (Badges/QR)', controller: _shortNameCtrl, hint: 'e.g. Summit-26'),
        const SizedBox(height: 14),
        _inputField(
          label: 'Event Description *',
          controller: _descCtrl,
          hint: 'Detailed operational charter, session outcomes, and participant prerequisites...',
          maxLines: 3,
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _dropdownField<EventCategory>(
                label: 'Event Category',
                value: _category,
                items: EventCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdownField<EventPriority>(
                label: 'Priority Matrix',
                value: _priority,
                items: EventPriority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.displayName))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _priority = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _dropdownField<EventVisibility>(
          label: 'Event Visibility & Access Scope',
          value: _visibility,
          items: EventVisibility.values.map((v) => DropdownMenuItem(value: v, child: Text(v.displayName))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _visibility = v);
          },
        ),
      ],
    );
  }

  // STEP 2: Schedule & Agenda
  Widget _buildStep2Schedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date, Timing & Scheduling Parameters',
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'GroundFlow automated scheduling engine factors walking buffers and setup windows.',
          style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 16),

        // Date selection
        Row(
          children: [
            Expanded(
              child: _datePickerTile(
                label: 'Event Start Date',
                date: _startDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _datePickerTile(
                label: 'Event End Date',
                date: _endDate,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Time pickers
        Row(
          children: [
            Expanded(
              child: _timePickerTile(
                label: 'Start Time',
                time: _startTime,
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _startTime);
                  if (picked != null) setState(() => _startTime = picked);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _timePickerTile(
                label: 'End Time',
                time: _endTime,
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _endTime);
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('All-Day Event Protocol', style: GoogleFonts.roboto(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('Removes minute-level constraints and activates 24-hour venue custody', style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver)),
          value: _isAllDay,
          activeColor: GlassTheme.accentEmerald,
          onChanged: (v) => setState(() => _isAllDay = v),
        ),

        const SizedBox(height: 12),
        const Divider(color: GlassTheme.border),
        const SizedBox(height: 12),

        Text(
          'Buffer & Setup Automation',
          style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _counterTile(
                label: 'Setup Buffer (Hours)',
                value: _setupDuration,
                onChanged: (v) => setState(() => _setupDuration = v.clamp(0, 48)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _counterTile(
                label: 'Breakdown Buffer (Hours)',
                value: _breakdownDuration,
                onChanged: (v) => setState(() => _breakdownDuration = v.clamp(0, 48)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: Venue & Hybrid
  Widget _buildStep3Venue() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Venue, Location & Hybrid Delivery',
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 12),

        // Location Mode Segmented
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlassTheme.border),
          ),
          child: Row(
            children: LocationMode.values.map((mode) {
              final isSel = _locationMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _locationMode = mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? GlassTheme.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        mode.displayName,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.black : GlassTheme.chrome,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 18),

        if (_locationMode != LocationMode.online) ...[
          _inputField(label: 'Venue Name *', controller: _venueNameCtrl, hint: 'e.g. MIT Pune Central Ground'),
          const SizedBox(height: 12),
          _inputField(label: 'Full Street Address', controller: _addressCtrl, hint: 'e.g. S.No 124, Paud Road'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _inputField(label: 'City', controller: _cityCtrl, hint: 'Pune')),
              const SizedBox(width: 12),
              Expanded(child: _inputField(label: 'Total Capacity Ceiling', controller: _capacityCtrl, hint: '500', isNumber: true)),
            ],
          ),
          const SizedBox(height: 14),

          Text('Available Facilities (Multi-Select)', style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Wi-Fi',
              'Audio System',
              'Projector',
              'LED Wall',
              'Power Backup',
              'Microphones',
              'Seating',
              'Stage',
              'Air Conditioning',
              'Washrooms',
              'Parking',
              'Security Access',
              'Wheelchair Ramp',
            ].map((facility) {
              final isChecked = _selectedFacilities.contains(facility);
              return FilterChip(
                label: Text(facility, style: GoogleFonts.roboto(fontSize: 11.5, color: isChecked ? Colors.black : Colors.white)),
                selected: isChecked,
                selectedColor: GlassTheme.white,
                backgroundColor: const Color(0xFF141418),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: GlassTheme.border)),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedFacilities.add(facility);
                    } else {
                      _selectedFacilities.remove(facility);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],

        if (_locationMode != LocationMode.physical) ...[
          const SizedBox(height: 18),
          Text('Virtual Meeting Configuration', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 10),
          _inputField(label: 'Meeting URL *', controller: _virtualUrlCtrl, hint: 'https://meet.google.com/xyz-abc-def or Zoom link'),
        ],
      ],
    );
  }

  // STEP 4: Ownership
  Widget _buildStep4Ownership() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department Ownership & Escalation Leads',
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Defines who holds administrative budget sign-off and receives 5-minute task escalations.',
          style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 16),

        _dropdownField<String>(
          label: 'Primary Department *',
          value: _primaryDept,
          items: [
            'Operations',
            'Human Resources',
            'Marketing',
            'Engineering / IT',
            'Finance',
            'Administration',
            'Security',
            'Media & Broadcast',
          ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _primaryDept = v);
          },
        ),
        const SizedBox(height: 14),

        _inputField(label: 'Event Owner Email (Charter Holder) *', controller: _ownerEmailCtrl, hint: 'owner@campus.edu'),
        const SizedBox(height: 14),
        _inputField(label: 'Department Head Email (Approving Authority) *', controller: _headEmailCtrl, hint: 'head@campus.edu'),
        const SizedBox(height: 14),
        _inputField(label: 'Event Coordinator Email (On-Ground Lead) *', controller: _coordEmailCtrl, hint: 'coordinator@campus.edu'),
      ],
    );
  }

  // STEP 5: Headcount & Budget
  Widget _buildStep5HeadcountBudget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role-Segregated Headcount & Financial Allocations',
          style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          'Separate people by roles to automate walkie-talkie, badge, and catering resource orders.',
          style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _inputField(label: 'Total Expected Attendees', controller: _totalAttendanceCtrl, hint: '350', isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _inputField(label: 'VIP Delegates', controller: _vipCountCtrl, hint: '10', isNumber: true)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _inputField(label: 'Volunteers & Squad Crew', controller: _volunteersCountCtrl, hint: '45', isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _inputField(label: 'Keynote Speakers', controller: _speakersCountCtrl, hint: '6', isNumber: true)),
          ],
        ),

        const SizedBox(height: 18),
        const Divider(color: GlassTheme.border),
        const SizedBox(height: 14),

        Text('Budget & Cost Center', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _inputField(label: 'Estimated Budget (INR/USD)', controller: _estimatedBudgetCtrl, hint: '75000', isNumber: true)),
            const SizedBox(width: 12),
            Expanded(child: _inputField(label: 'Cost Center Code', controller: _costCenterCtrl, hint: 'CC-OPS-2026')),
          ],
        ),
      ],
    );
  }

  // STEP 6: Dynamic Department Fields
  Widget _buildStep6DynamicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlassTheme.accentSky.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune_rounded, color: GlassTheme.accentSky, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedTemplate.name} Parameters',
                    style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    'Dynamic schema tailored specifically for ${_selectedTemplate.defaultPrimaryDept}.',
                    style: GoogleFonts.roboto(fontSize: 11, color: GlassTheme.mutedSilver),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        ..._dynamicFieldControllers.entries.map((entry) {
          final label = _formatKeyToLabel(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _inputField(
              label: label,
              controller: entry.value,
              hint: 'Configure $label...',
            ),
          );
        }),
      ],
    );
  }

  // STEP 7: Automation & Review
  Widget _buildStep7AutomationReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141419),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlassTheme.accentEmerald.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: GlassTheme.accentEmerald, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Universal Automation Ready', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      'GroundFlow will automatically provision workspaces, seed team workflows, and activate live telemetry upon creation.',
                      style: GoogleFonts.roboto(fontSize: 11.5, color: GlassTheme.mutedSilver),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text('Summary Review', style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 10),
        _reviewRow('Event Title', _titleCtrl.text),
        _reviewRow('Event Code / ID', _codeCtrl.text.toUpperCase()),
        _reviewRow('Event Password / Passcode', _passwordCtrl.text.isNotEmpty ? '••••••••' : 'None'),
        _reviewRow('Primary Department', _primaryDept),
        _reviewRow('Template Applied', _selectedTemplate.name),
        _reviewRow('Venue', _locationMode == LocationMode.online ? 'Virtual (${_virtualUrlCtrl.text})' : _venueNameCtrl.text),
        _reviewRow('Estimated Headcount', '${_totalAttendanceCtrl.text} Attendees (${_volunteersCountCtrl.text} Volunteers)'),
        _reviewRow('Estimated Budget', '${_estimatedBudgetCtrl.text} (${_costCenterCtrl.text})'),

        const SizedBox(height: 18),
        Text('Automated Workflows to be Seeded (${_selectedTemplate.defaultTasks.length})', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),

        ..._selectedTemplate.defaultTasks.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(Icons.task_alt_rounded, size: 14, color: GlassTheme.accentSky),
              const SizedBox(width: 8),
              Expanded(child: Text(t, style: GoogleFonts.roboto(fontSize: 12, color: Colors.white70))),
            ],
          ),
        )),
      ],
    );
  }

  // Helper Widgets
  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.roboto(fontSize: 12, color: GlassTheme.mutedSilver)),
          Text(value.isEmpty ? '—' : value, style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool isNumber = false,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    final bool shouldObscure = isPassword && obscure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlassTheme.border),
          ),
          child: TextField(
            controller: controller,
            maxLines: shouldObscure ? 1 : maxLines,
            obscureText: shouldObscure,
            enableSuggestions: !isPassword,
            autocorrect: !isPassword,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.roboto(color: const Color(0xFF52525B), fontSize: 12.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        color: GlassTheme.chrome,
                        size: 18,
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlassTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF141418),
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePickerTile({required String label, required DateTime date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C0E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
                ),
                const Icon(Icons.calendar_today_rounded, size: 16, color: GlassTheme.chrome),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timePickerTile({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0C0E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GlassTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 13),
                ),
                const Icon(Icons.access_time_rounded, size: 16, color: GlassTheme.chrome),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _counterTile({required String label, required int value, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.roboto(fontSize: 11.5, fontWeight: FontWeight.w600, color: GlassTheme.chrome)),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0C0E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlassTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                onPressed: () => onChanged(value - 1),
              ),
              Text('$value hrs', style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'people':
        return Icons.people_outline_rounded;
      case 'campaign':
        return Icons.campaign_outlined;
      case 'code':
        return Icons.code_rounded;
      case 'account_balance':
        return Icons.account_balance_outlined;
      default:
        return Icons.hub_rounded;
    }
  }

  String _formatKeyToLabel(String key) {
    final buffer = StringBuffer();
    for (int i = 0; i < key.length; i++) {
      if (i > 0 && key[i].toUpperCase() == key[i] && key[i - 1].toLowerCase() == key[i - 1]) {
        buffer.write(' ');
      }
      buffer.write(i == 0 ? key[i].toUpperCase() : key[i]);
    }
    return buffer.toString();
  }
}
