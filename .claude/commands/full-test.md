Run the comprehensive pre-commit test suite (90 seconds)

This runs:
- Build check
- All critical unit tests (CoreDataPersistence, TrainingLoadCalculator, RecoveryScore, CacheManager, MLModelRegistry, TSSCalculation, RecoveryCalculationFallback, UnifiedActivityService, ProgressiveTrainingLoad, APIAuthentication, CoreDataMigration)
- Essential lint check

Execute: ./scripts/full-test.sh
