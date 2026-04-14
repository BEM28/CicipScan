class InferenceResult {
  final String label;
  final double confidence;

  InferenceResult(this.label, this.confidence);

  @override
  String toString() {
    return 'InferenceResult(label: $label, confidence: ${confidence.toStringAsFixed(2)})';
  }
}
