// OpenTelemetry Web SDK bundle
import { trace } from '@opentelemetry/api';
import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-web';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
import { registerInstrumentations } from '@opentelemetry/instrumentation';

// Export all modules that app.js needs
export default {
    api: { trace },
    sdk: { WebTracerProvider, BatchSpanProcessor },
    resources: { Resource },
    semanticConventions: { SemanticResourceAttributes },
    exporter: { OTLPTraceExporter },
    instrumentation: { FetchInstrumentation, registerInstrumentations }
};
