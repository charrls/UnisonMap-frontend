import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/ruta_ors_model.dart' as ors_model;

typedef PasoFocusListener = void Function(ors_model.RutaStep? step);

class RutaController extends ChangeNotifier {
	ors_model.RutaORSResponse? _rutaActual;
	int _pasoActual = 0;
	Timer? _autoAdvanceTimer;
	PasoFocusListener? _focusListener;

	ors_model.RutaORSResponse? get rutaActual => _rutaActual;
	int get pasoActual => _pasoActual;
	List<ors_model.RutaStep> get pasos => _rutaActual?.instrucciones ?? const <ors_model.RutaStep>[];
	bool get tieneInstrucciones => pasos.isNotEmpty;
	bool get puedeAvanzar => tieneInstrucciones && _pasoActual < pasos.length - 1;
	bool get puedeRetroceder => tieneInstrucciones && _pasoActual > 0;
	ors_model.RutaStep? get pasoSiguiente => obtenerPaso(_pasoActual + 1);

	void setFocusListener(PasoFocusListener? listener) {
		_focusListener = listener;
		_notifyStepFocus();
	}

	void setRuta(ors_model.RutaORSResponse? ruta) {
		_rutaActual = ruta;
		final int backendIndex = ruta?.currentStepIndex ?? 0;
		_pasoActual = backendIndex.clamp(0, pasos.isEmpty ? 0 : pasos.length - 1);
		_notifyStepFocus();
		notifyListeners();
	}

	void limpiarRuta() {
		_rutaActual = null;
		_pasoActual = 0;
		detenerAvanceAutomatico();
		_notifyStepFocus();
		notifyListeners();
	}

	void siguientePaso() {
		if (!puedeAvanzar) {
			detenerAvanceAutomatico();
			return;
		}
		_pasoActual++;
		_notifyStepFocus();
		notifyListeners();
	}

	void pasoAnterior() {
		if (!puedeRetroceder) {
			return;
		}
		_pasoActual--;
		_notifyStepFocus();
		notifyListeners();
	}

	void irAPaso(int index) {
		if (pasos.isEmpty) {
			return;
		}

		final int nuevoIndice = index.clamp(0, pasos.length - 1);
		if (nuevoIndice == _pasoActual) {
			return;
		}

		_pasoActual = nuevoIndice;
		detenerAvanceAutomatico();
		_notifyStepFocus();
		notifyListeners();
	}

	void avanzarAutomaticamente({Duration interval = const Duration(seconds: 5)}) {
		if (pasos.length <= 1) {
			return;
		}

		detenerAvanceAutomatico();
		_autoAdvanceTimer = Timer.periodic(interval, (_) {
			if (!puedeAvanzar) {
				detenerAvanceAutomatico();
				return;
			}
			siguientePaso();
		});
	}

	void detenerAvanceAutomatico() {
		_autoAdvanceTimer?.cancel();
		_autoAdvanceTimer = null;
	}

	ors_model.RutaStep? obtenerPaso(int index) {
		if (index < 0 || index >= pasos.length) {
			return null;
		}
		return pasos[index];
	}

	void sincronizarIndiceBackend(int? index) {
		if (index == null || pasos.isEmpty) {
			return;
		}

		final int nuevoIndice = index.clamp(0, pasos.length - 1);
		if (nuevoIndice == _pasoActual) {
			return;
		}

		_pasoActual = nuevoIndice;
		_notifyStepFocus();
		notifyListeners();
	}

	void _notifyStepFocus() {
		_focusListener?.call(pasoActualActual);
	}

	ors_model.RutaStep? get pasoActualActual => obtenerPaso(_pasoActual);

	@override
	void dispose() {
		detenerAvanceAutomatico();
		super.dispose();
	}
}
