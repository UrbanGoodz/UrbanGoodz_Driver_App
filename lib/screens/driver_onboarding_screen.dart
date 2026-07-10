import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urban_goodz_driver/controllers/driver_auth_controller.dart';
import 'package:urban_goodz_driver/theme/app_theme.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final DriverAuthController authController = Get.find<DriverAuthController>();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'James Doe');
  final _phoneController = TextEditingController(text: '+1 (713) 555-0100');
  final _emailController = TextEditingController(text: 'james.doe@urbangoodz.com');
  final _cityController = TextEditingController(text: 'Houston, TX');
  final _vehicleDetailsController = TextEditingController(text: 'Toyota Camry 2022');
  final _tokenController = TextEditingController();

  String _selectedVehicleType = 'Sedan';
  final List<String> _vehicleTypes = ['Sedan', 'Van', 'Truck', 'Motorcycle', 'Bicycle'];

  bool _serviceOrderAnywhere = true;
  bool _serviceDelivery = true;
  bool _serviceCourier = true;
  bool _serviceMedical = true;
  bool _serviceLogistics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.beige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_shipping, color: AppTheme.primary, size: 64),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Urban Goodz Driver',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.dark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Ecosystem Tester Portal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Section
                const Text(
                  'Driver Profile Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City / Operating Zone',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                // Driver API Token (required to talk to the live backend)
                const Text(
                  'Driver API Token',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Bearer Token',
                    prefixIcon: Icon(Icons.key_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Token required to load real jobs'
                      : null,
                ),
                const SizedBox(height: 24),

                // Vehicle Section
                const Text(
                  'Vehicle Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  initialValue: _selectedVehicleType,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _vehicleTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedVehicleType = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _vehicleDetailsController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Details (Make/Model/Year)',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                
                // Services Section
                const Text(
                  'Eligible Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 8),
                
                CheckboxListTile(
                  title: const Text('Order Anywhere Tasks'),
                  subtitle: const Text('Custom shopping / pick up requests'),
                  value: _serviceOrderAnywhere,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _serviceOrderAnywhere = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Standard Store Delivery'),
                  subtitle: const Text('Restaurant / grocery orders'),
                  value: _serviceDelivery,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _serviceDelivery = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Courier Runs'),
                  subtitle: const Text('Light packages and documents'),
                  value: _serviceCourier,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _serviceCourier = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Medical Courier (Beta)'),
                  subtitle: const Text('Lab tests / specimen transport'),
                  value: _serviceMedical,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _serviceMedical = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Logistics / Load Board (Beta)'),
                  subtitle: const Text('Heavy freight / cargo shifts'),
                  value: _serviceLogistics,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _serviceLogistics = val ?? false),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Save state
                      authController.name.value = _nameController.text;
                      authController.phone.value = _phoneController.text;
                      authController.email.value = _emailController.text;
                      authController.city.value = _cityController.text;
                      authController.vehicleType.value = _selectedVehicleType;
                      authController.vehicleDetails.value = _vehicleDetailsController.text;
                      authController.serviceOrderAnywhere.value = _serviceOrderAnywhere;
                      authController.serviceDelivery.value = _serviceDelivery;
                      authController.serviceCourier.value = _serviceCourier;
                      authController.serviceMedicalCourier.value = _serviceMedical;
                      authController.serviceLogistics.value = _serviceLogistics;
                      authController.setToken(_tokenController.text);
                      authController.isLoggedIn.value = true;
                      
                      Get.snackbar(
                        'Access Granted',
                        'Welcome to the Urban Goodz driver ecosystem!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: const Text(
                    'ENTER TESTER DRIVER MODE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
