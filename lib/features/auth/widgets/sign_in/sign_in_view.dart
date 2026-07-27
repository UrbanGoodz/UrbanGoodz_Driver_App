import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/config_model.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/enum/centralize_login_enum.dart';
import 'package:sixam_mart/features/auth/screens/new_user_setup_screen.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/manual_login_widget.dart';
import 'package:sixam_mart/features/auth/widgets/sign_in/otp_login_widget.dart';
import 'package:sixam_mart/features/auth/widgets/social_login_widget.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/verification/domein/enum/verification_type_enum.dart';
import 'package:sixam_mart/features/verification/screens/verification_screen.dart';
import 'package:sixam_mart/helper/centralize_login_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';

class SignInView extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromResetPassword;
  final Function(bool val)? isOtpViewEnable;
  const SignInView({super.key, required this.exitFromApp, required this.backFromThis, this.fromResetPassword = false, this.isOtpViewEnable});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyLogin;
  bool _prevOtpViewEnable = false;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    AuthController authController  = Get.find<AuthController>();
    SplashController splashController = Get.find<SplashController>();

    WidgetsBinding.instance.addPostFrameCallback((_){
      // Pre-filling the form is a convenience, not a precondition for showing
      // it. When the backend config is missing there is nothing to pre-fill
      // against, so skip it -- build() renders the unavailable state. Throwing
      // here previously took the whole login screen down with it.
      final centralizeLoginSetup =
          splashController.configModel?.centralizeLoginSetup;
      if (centralizeLoginSetup == null) {
        return;
      }

      CentralizeLoginType loginType = CentralizeLoginHelper.getPreferredLoginMethod(
        centralizeLoginSetup, authController.isOtpViewEnable,
      ).type;

      bool isOtpActive = loginType == CentralizeLoginType.otp || loginType == CentralizeLoginType.otpAndSocial;

      // Falls back to an empty dial code rather than asserting on country:
      // an absent country must not crash a screen the shopper needs.
      final configCountry = splashController.configModel?.country;
      final defaultDialCode = configCountry == null
          ? ''
          : CountryCode.fromCountryCode(configCountry).dialCode ?? '';

      if (isOtpActive) {
        // Pre-fill from OTP-specific storage
        String otpNumber = authController.getOtpUserNumber();
        String otpCountryCode = authController.getOtpUserCountryCode();
        _countryDialCode = otpCountryCode.isNotEmpty
            ? otpCountryCode
            : defaultDialCode;
        _phoneController.text = otpNumber;
      } else {
        // Pre-fill from manual-specific storage
        String manualNumber = authController.getUserNumber();
        String manualCountryCode = authController.getUserCountryCode();
        _countryDialCode = manualCountryCode.isNotEmpty
            ? manualCountryCode
            : defaultDialCode;
        _phoneController.text = manualNumber;
        _passwordController.text = authController.getUserPassword();
      }

      if (_phoneController.text.isNotEmpty && !_phoneController.text.contains('@')) {
        authController.toggleIsNumberLogin(value: true);
      } else {
        authController.toggleIsNumberLogin(value: false);
      }
      authController.initCountryCode(countryCode: _countryDialCode != "" ? _countryDialCode : null);
    });

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          FocusScope.of(Get.context!).requestFocus(_phoneFocus);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (authController) {
      // Restore manual credentials when navigating back from OTP view
      if (_prevOtpViewEnable && !authController.isOtpViewEnable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _phoneController.text = authController.getUserNumber();
          _passwordController.text = authController.getUserPassword();
          String savedCountryCode = authController.getUserCountryCode();
          if (savedCountryCode.isNotEmpty) {
            _countryDialCode = savedCountryCode;
            authController.initCountryCode(countryCode: savedCountryCode);
          }
          if (_phoneController.text.isNotEmpty && !_phoneController.text.contains('@')) {
            authController.toggleIsNumberLogin(value: true);
          } else {
            authController.toggleIsNumberLogin(value: false);
          }
        });
      }
      _prevOtpViewEnable = authController.isOtpViewEnable;

      // Which login methods to offer comes from the backend config. When that
      // config did not load -- offline start, slow network, backend hiccup --
      // this used to force-unwrap and throw, replacing the whole login screen
      // with a crash. A shopper who cannot reach config must still see a
      // screen that explains itself and offers a retry.
      final centralizeLoginSetup =
          Get.find<SplashController>().configModel?.centralizeLoginSetup;
      if (centralizeLoginSetup == null) {
        return _signInUnavailable();
      }

      return Form(
        key: _formKeyLogin,
        child: activeCentralizeLogin(centralizeLoginSetup, authController),
      );
    });
  }

  /// Shown when the backend sign-in configuration is not available.
  ///
  /// Deliberately states the real reason and offers a retry rather than
  /// rendering an empty form that could not submit anyway.
  Widget _signInUnavailable() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          // Literal rather than .tr: these two keys are not in the shipped
          // language assets, and GetX renders a missing key as the raw key
          // name, which would put "sign_in_is_temporarily_unavailable" on
          // screen. English text is the honest fallback until the keys are
          // added to every locale file.
          const Text(
            'Sign-in is temporarily unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'We could not load the sign-in settings. Check your connection '
            'and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                Get.find<SplashController>().getConfigData(),
            child: Text('retry'.tr),
          ),
        ],
      ),
    ),
  );

  Widget activeCentralizeLogin(CentralizeLoginSetup centralizeLoginSetup, AuthController authController) {
    CentralizeLoginType centralizeLogin = CentralizeLoginHelper.getPreferredLoginMethod(centralizeLoginSetup, authController.isOtpViewEnable).type;
    switch (centralizeLogin) {
      case CentralizeLoginType.otp:
        return OtpLoginWidget(
          phoneController: _phoneController, phoneFocus: _phoneFocus,
          countryDialCode: _countryDialCode, backFromThis: widget.backFromThis,
          onCountryChanged: (CountryCode countryCode) => _countryDialCode = countryCode.dialCode,
          onClickLoginButton: () {
            _otpLogin(Get.find<AuthController>(), _countryDialCode!, CentralizeLoginType.otp);
          },
        );

      case CentralizeLoginType.manual:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController,
          phoneFocus: _phoneFocus, passwordFocus: _passwordFocus, onWebSubmit: (){}, backFromThis: widget.backFromThis,
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.social:
        return SocialLoginWidget(onlySocialLogin: true, backFromThis: widget.backFromThis);

      case CentralizeLoginType.manualAndSocial:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController, phoneFocus: _phoneFocus, passwordFocus: _passwordFocus,
          socialEnable: true, backFromThis: widget.backFromThis,
          onWebSubmit: (){}, onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.manualAndOtp:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController, phoneFocus: _phoneFocus,
          passwordFocus: _passwordFocus, backFromThis: widget.backFromThis,
          onOtpViewClick: () {
            widget.isOtpViewEnable!(true);
            // Always replace phone field with OTP-remembered number (clears manual number)
            AuthController ac = Get.find<AuthController>();
            String otpNumber = ac.getOtpUserNumber();
            String otpCountryCode = ac.getOtpUserCountryCode();
            _phoneController.text = otpNumber;
            if (otpCountryCode.isNotEmpty) {
              _countryDialCode = otpCountryCode;
            }
            setState(() {
              authController.enableOtpView(enable: true);
            });
          },
          onWebSubmit: (){},
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.otpAndSocial:
        return SocialLoginWidget(onlySocialLogin: true, backFromThis: widget.backFromThis, onOtpViewClick: (){
          widget.isOtpViewEnable!(true);
          if(_countryDialCode != "" && _phoneController.text != "" && _phoneController.text.contains('@')) {
            _phoneController.text = '';
          }
          setState(() {
            authController.enableOtpView(enable: true);
          });
        });

      case CentralizeLoginType.manualAndSocialAndOtp:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController, phoneFocus: _phoneFocus, passwordFocus: _passwordFocus,
          onWebSubmit: (){}, socialEnable: true, backFromThis: widget.backFromThis,
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
          onOtpViewClick: () {
            widget.isOtpViewEnable!(true);
            // Always replace phone field with OTP-remembered number (clears manual number)
            AuthController ac = Get.find<AuthController>();
            String otpNumber = ac.getOtpUserNumber();
            String otpCountryCode = ac.getOtpUserCountryCode();
            _phoneController.text = otpNumber;
            if (otpCountryCode.isNotEmpty) {
              _countryDialCode = otpCountryCode;
            }
            setState(() {
              authController.enableOtpView(enable: true);
            });
          },
        );

      }
  }
  
  void _otpLogin(AuthController authController, String countryDialCode, CentralizeLoginType loginType) async {
    String phone = _phoneController.text.trim();
    String numberWithCountryCode = countryDialCode+phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(_formKeyLogin!.currentState!.validate()) {
      if(!phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        authController.otpLogin(phone: numberWithCountryCode, otp: '', loginType: loginType.name, verified: '', alreadyInApp: widget.backFromThis).then((response) {
          if (response.isSuccess) {
            _processOtpSuccessSetup(response, authController, phone, countryDialCode);
          } else {
            showCustomSnackBar(response.message);
          }
        });
      }
    }
  }

  void _login(AuthController authController, CentralizeLoginType loginType) async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String numberWithCountryCode = authController.countryDialCode + phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(_formKeyLogin!.currentState!.validate()) {

      String isPhone = ValidateCheck.getValidPhone(authController.countryDialCode + _phoneController.text.trim(), withCountryCode: true);

      if(isPhone != "" && !phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        authController.login(
          emailOrPhone: isPhone != "" ? isPhone : phone, password: password,
          loginType: loginType.name, fieldType: isPhone !="" ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
          alreadyInApp: widget.backFromThis,
        ).then((status) async {
          if (status.isSuccess) {
            if(status.isSuccess && !status.authResponseModel!.isPersonalInfo!) {
              if(ResponsiveHelper.isDesktop(Get.context)) {
                Get.back();
                Get.dialog(NewUserSetupScreen(name: '', loginType: loginType.name, phone: numberWithCountryCode, email: '', backFromThis: widget.backFromThis));
              } else {
                Get.toNamed(RouteHelper.getNewUserSetupScreen(name: '', loginType: loginType.name, phone: numberWithCountryCode, email: '', backFromThis: widget.backFromThis));
              }
            } else {
              _processSuccessSetup(authController, phone, isPhone, password, status);
            }
          } else {
            showCustomSnackBar(status.message);
          }
        });
      }

    }
  }

  Future<void> _processSuccessSetup(AuthController authController, String phone, String email, String password, ResponseModel status) async {
    // Manual login remember me — saves to manual-specific keys only
    if (authController.isActiveRememberMe) {
      authController.saveUserNumberAndPassword(phone, password, authController.countryDialCode);
    } else {
      authController.clearUserNumberAndPassword();
    }
    if(Get.find<AddressController>().addressList == null) {
      Get.find<AddressController>().getAddressList();
    }
    if(GetPlatform.isWeb){
      // await Get.find<FavouriteController>().getFavouriteList();
    }
    if(status.authResponseModel != null && !status.authResponseModel!.isPhoneVerified!) {
      List<int> encoded = utf8.encode(password);
      String data = base64Encode(encoded);
      String token = status.authResponseModel!.token??'';
      if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
        Get.find<AuthController>().firebaseVerifyPhoneNumber(phone, token, CentralizeLoginType.manual.name, fromSignUp: true);
      } else {
        Get.toNamed(RouteHelper.getVerificationRoute(phone, null, token, RouteHelper.signUp, data, CentralizeLoginType.manual.name),
        );
      }
    } else if(status.authResponseModel != null && !status.authResponseModel!.isEmailVerified!) {
      List<int> encoded = utf8.encode(password);
      String data = base64Encode(encoded);
      String token = status.authResponseModel!.token??'';
      Get.toNamed(RouteHelper.getVerificationRoute(null, email, token, RouteHelper.signUp, data, CentralizeLoginType.manual.name));
    } else {
      if(widget.backFromThis) {
        if(ResponsiveHelper.isDesktop(Get.context) || widget.fromResetPassword){
          Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: false));
        } else {
          Get.back();
        }
      } else {
        Get.find<LocationController>().navigateToLocationScreen('sign-in', offNamed: true);
      }
    }
  }

  void _processOtpSuccessSetup(ResponseModel response, AuthController authController, String phone, String countryDialCode) async {
    // OTP login remember me — saves to OTP-specific keys only
    if (authController.isActiveRememberMeOtp) {
      authController.saveOtpUserNumber(phone, countryDialCode);
    } else {
      authController.clearOtpUserNumber();
    }
    if(GetPlatform.isWeb && response.authResponseModel == null){
      await Get.find<FavouriteController>().getFavouriteList();
    }
    if(response.authResponseModel != null && !response.authResponseModel!.isPhoneVerified!) {
      if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
        Get.find<AuthController>().firebaseVerifyPhoneNumber(countryDialCode + phone, '', CentralizeLoginType.otp.name, fromSignUp: true);
      } else {
        if(ResponsiveHelper.isDesktop(Get.context)) {
          Get.back();
          Get.dialog(VerificationScreen(
            number: countryDialCode + phone, email: null, token: '', fromSignUp: true,
            fromForgetPassword: false, loginType: CentralizeLoginType.otp.name, password: '',
          ));
        } else {
          Get.toNamed(RouteHelper.getVerificationRoute(
            countryDialCode + phone, null, '', RouteHelper.signUp, null, CentralizeLoginType.otp.name,
            backFromThis: widget.backFromThis,
          ));
        }
      }
    } else {
      if(widget.backFromThis) {
        if(ResponsiveHelper.isDesktop(Get.context)){
          Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: false));
        } else {
          Get.back();
        }
      }else {
        Get.find<LocationController>().navigateToLocationScreen('sign-in', offNamed: true);
      }
    }
  }
}