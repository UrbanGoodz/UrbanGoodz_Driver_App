import 'package:get/get.dart';
import 'package:urban_goodz_driver/models/purchase_card_model.dart';
import 'package:urban_goodz_driver/services/api_client.dart';
import 'package:urban_goodz_driver/services/driver_api_service.dart';

/// Progress of a receipt submission, kept separate from the card lifecycle so
/// a failed upload never mutates what the driver is told about the card.
enum ReceiptUploadPhase { idle, uploading, success, failed }

/// Drives the Order Anywhere purchase-card screen.
///
/// Two invariants shape this class:
///
/// 1. The driver never creates a card. There is no issue/create call here at
///    all — the backend issues automatically once eligibility and provider
///    configuration are satisfied. Refresh is a plain GET, and concurrent
///    refreshes are collapsed so hammering the button cannot fan out into
///    repeated server work.
/// 2. Nothing is fabricated. A failed load leaves [state] null and surfaces an
///    error; it never substitutes an empty card that would render as zeroes.
class PurchaseCardController extends GetxController {
  PurchaseCardController({required this.requestId, DriverApiService? api})
    : _injectedApi = api;

  final int requestId;
  final DriverApiService? _injectedApi;

  DriverApiService get _api => _injectedApi ?? Get.find<DriverApiService>();

  final Rxn<PurchaseCardState> state = Rxn<PurchaseCardState>();
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  final Rx<ReceiptUploadPhase> receiptPhase = ReceiptUploadPhase.idle.obs;
  final RxnString receiptError = RxnString();

  final RxBool reportingFailure = false.obs;
  final RxnString failureError = RxnString();

  final RxBool revealLoading = false.obs;
  final RxnString revealError = RxnString();

  /// Guards against overlapping refreshes. A second tap while a request is in
  /// flight is a no-op rather than a second round trip.
  bool _refreshInFlight = false;

  /// Counts completed loads so tests (and the device check) can prove that
  /// repeated refreshes do not multiply into extra issuance work.
  int get loadCount => _loadCount;
  int _loadCount = 0;

  @override
  void onInit() {
    super.onInit();
    refreshCard();
  }

  /// Fetches current card state. Safe to call repeatedly: it is a read, and
  /// overlapping calls are collapsed.
  Future<void> refreshCard() async {
    if (_refreshInFlight) return;
    _refreshInFlight = true;
    loading.value = true;
    error.value = null;

    try {
      final envelope = await _api.getPurchaseCard(requestId);
      state.value = PurchaseCardState.fromEnvelope(
        envelope,
        requestId: requestId,
      );
      _loadCount++;
    } on ApiException catch (e) {
      // 401 teardown is handled centrally by ApiClient.onUnauthorized; here we
      // only need the driver-safe message. The previous state is deliberately
      // left untouched so a transient failure does not blank a valid card.
      error.value = _safeMessage(e);
    } catch (_) {
      error.value =
          'Could not load your purchase card. Check your connection and try again.';
    } finally {
      loading.value = false;
      _refreshInFlight = false;
    }
  }

  /// Requests a provider-hosted reveal session.
  ///
  /// Refuses locally unless [PurchaseCardState.canReveal] holds, so a
  /// provider-unconfigured or non-live card never reaches the network. Returns
  /// null on refusal or failure; the caller must not open a secure view then.
  Future<CardRevealSession?> startReveal() async {
    final current = state.value;
    revealError.value = null;

    if (current == null || !current.canReveal) {
      revealError.value = 'Secure reveal is not available for this card.';
      return null;
    }

    revealLoading.value = true;
    try {
      final json = await _api.createCardRevealSession(requestId);
      final session = CardRevealSession.fromJson(json);
      if (session == null) {
        revealError.value =
            'Secure reveal could not be started. Please try again.';
        return null;
      }
      if (session.isExpired) {
        revealError.value = 'The secure reveal session expired. Try again.';
        return null;
      }
      return session;
    } on ApiException catch (e) {
      revealError.value = _safeMessage(e);
      return null;
    } catch (_) {
      revealError.value =
          'Secure reveal could not be started. Please try again.';
      return null;
    } finally {
      revealLoading.value = false;
    }
  }

  /// Uploads a receipt for this assignment.
  ///
  /// [allowResubmit] must be set explicitly to replace a receipt that has
  /// already been accepted, so an accidental second submission cannot silently
  /// overwrite a reconciled figure.
  Future<bool> uploadReceipt({
    required String filePath,
    required double total,
    String? notes,
    bool allowResubmit = false,
  }) async {
    final current = state.value;
    receiptError.value = null;

    if (current == null || !current.canUploadReceipt) {
      receiptError.value =
          'A receipt cannot be submitted for this card right now.';
      receiptPhase.value = ReceiptUploadPhase.failed;
      return false;
    }
    if (current.receiptSubmitted && !allowResubmit) {
      receiptError.value =
          'A receipt has already been submitted for this purchase.';
      receiptPhase.value = ReceiptUploadPhase.failed;
      return false;
    }
    if (total <= 0) {
      receiptError.value = 'Enter the total shown on the receipt.';
      receiptPhase.value = ReceiptUploadPhase.failed;
      return false;
    }
    // Collapse double-taps on the submit button.
    if (receiptPhase.value == ReceiptUploadPhase.uploading) return false;

    receiptPhase.value = ReceiptUploadPhase.uploading;
    try {
      await _api.uploadPurchaseReceipt(
        requestId,
        receiptPath: filePath,
        receiptTotal: total,
        notes: notes,
      );
      receiptPhase.value = ReceiptUploadPhase.success;
      await refreshCard();
      return true;
    } on ApiException catch (e) {
      receiptError.value = _safeMessage(e);
      receiptPhase.value = ReceiptUploadPhase.failed;
      return false;
    } catch (_) {
      receiptError.value = 'Receipt upload failed. You can retry.';
      receiptPhase.value = ReceiptUploadPhase.failed;
      return false;
    }
  }

  /// Clears a failed upload so the retry control starts from a clean state.
  void resetReceiptUpload() {
    receiptPhase.value = ReceiptUploadPhase.idle;
    receiptError.value = null;
  }

  /// Reports a structured failure category. Only the fixed category and the
  /// driver's own notes are transmitted — never card credentials, provider
  /// tokens or reveal URLs.
  Future<bool> reportFailure(
    CardFailureCategory category, {
    String? notes,
  }) async {
    failureError.value = null;
    if (reportingFailure.value) return false;

    reportingFailure.value = true;
    try {
      await _api.reportPurchaseCardFailure(
        requestId,
        category: category.wireValue,
        details: category.detailFor(notes),
      );
      await refreshCard();
      return true;
    } on ApiException catch (e) {
      failureError.value = _safeMessage(e);
      return false;
    } catch (_) {
      failureError.value = 'Could not send your report. Please try again.';
      return false;
    } finally {
      reportingFailure.value = false;
    }
  }

  /// Maps a transport failure onto driver-safe wording.
  ///
  /// Server messages are surfaced verbatim for the statuses where they are
  /// written for the driver, and replaced for the ones where the raw text can
  /// carry internal detail.
  String _safeMessage(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Your session expired. Please sign in again.';
      case 403:
        return 'This purchase card belongs to a different driver assignment.';
      case 404:
        return 'No purchase card was found for this order.';
      case 422:
        return e.message.isNotEmpty
            ? e.message
            : 'That action is not allowed for this card right now.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Something went wrong. Please try again or contact support.';
    }
  }
}
