---
id: react-performance-standards
last_modified: '2025-01-10'
version: '0.2.0'
derived_from: automation
enforced_by: 'Core Web Vitals monitoring, Bundle analysis, CI performance gates'
---

# Binding: React Performance Standards

Establish hard performance targets for React meta-framework applications: LCP < 2.5s, initial JavaScript bundle < 200KB, TTI < 3.5s. Leverage server-first architecture to achieve performance by default while implementing systematic monitoring and optimization patterns that prevent performance regressions.

## Rationale

This binding implements our automation tenet by establishing measurable performance standards that prevent the gradual performance degradation common in client-heavy React applications. Performance problems in production are exponentially more expensive to fix than those caught during development, yet most React applications ship without systematic performance validation.

Server-first architecture provides a foundation for performance by default, but requires explicit standards to maintain performance characteristics as applications grow. Without clear targets and measurement, teams often discover performance issues only when users complain or Core Web Vitals affect SEO rankings.

Performance standards act as quality gates that catch regressions early while providing clear optimization targets. The key is establishing realistic, measurable targets based on user expectations and business requirements rather than arbitrary thresholds that become obstacles to delivery.

## Rule Definition

This rule applies to all React applications using Next.js App Router or Remix. The rule specifically requires:

**Core Web Vitals Targets:**
- **Largest Contentful Paint (LCP)**: < 2.5 seconds for 75th percentile of page loads
- **First Input Delay (FID) / Interaction to Next Paint (INP)**: < 100ms for 75th percentile of interactions
- **Cumulative Layout Shift (CLS)**: < 0.1 for 75th percentile of page loads

**JavaScript Performance Targets:**
- **Initial JavaScript bundle**: < 200KB compressed for route entry point
- **Time to Interactive (TTI)**: < 3.5 seconds for 75th percentile of page loads
- **Server Components ratio**: > 80% of components should be Server Components
- **Client JavaScript growth**: < 10KB per major feature addition

**Optimization Requirements:**
- **Image optimization**: All images must use framework-provided optimized components
- **Code splitting**: Route-based code splitting enabled by default
- **Streaming SSR**: Server-rendered content must stream to browser
- **Performance monitoring**: Real User Monitoring (RUM) data collection required

## Practical Implementation

**Performance Measurement Setup:**
```typescript
// performance-config.ts
export const PERFORMANCE_TARGETS = {
  LCP: 2500,        // 2.5 seconds
  FID: 100,         // 100ms
  CLS: 0.1,         // 0.1 layout shift score
  TTI: 3500,        // 3.5 seconds
  BUNDLE_SIZE: 200, // 200KB compressed
} as const;

// Measurement utilities
export function measureCoreWebVitals() {
  import('web-vitals').then(({ getCLS, getFID, getFCP, getLCP, getTTFB }) => {
    getCLS(sendToAnalytics);
    getFID(sendToAnalytics);
    getFCP(sendToAnalytics);
    getLCP(sendToAnalytics);
    getTTFB(sendToAnalytics);
  });
}

function sendToAnalytics(metric: Metric) {
  // Send to your analytics service
  if (process.env.NODE_ENV === 'production') {
    analytics.track('Core Web Vital', {
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      delta: metric.delta,
    });
  }
}
```

**Next.js Performance Patterns:**
```typescript
// app/layout.tsx - Streaming layout
import { Suspense } from 'react';

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Suspense fallback={<NavSkeleton />}>
          <Navigation />
        </Suspense>

        <main>
          <Suspense fallback={<ContentSkeleton />}>
            {children}
          </Suspense>
        </main>

        <Suspense fallback={<FooterSkeleton />}>
          <Footer />
        </Suspense>
      </body>
    </html>
  );
}

// app/products/page.tsx - Optimized server component
import { Suspense } from 'react';
import Image from 'next/image';

async function ProductList() {
  const products = await getProducts(); // Server-side data fetching

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {products.map((product) => (
        <div key={product.id} className="product-card">
          <Image
            src={product.image}
            alt={product.name}
            width={300}
            height={200}
            priority={product.featured}
            placeholder="blur"
            blurDataURL="data:image/jpeg;base64,..."
          />
          <h3>{product.name}</h3>
          <p>${product.price}</p>
        </div>
      ))}
    </div>
  );
}

export default function ProductsPage() {
  return (
    <div>
      <h1>Products</h1>
      <Suspense fallback={<ProductListSkeleton />}>
        <ProductList />
      </Suspense>
    </div>
  );
}
```

**Remix Performance Patterns:**
```typescript
// app/routes/products._index.tsx
import type { LoaderFunctionArgs } from '@remix-run/node';
import { json } from '@remix-run/node';
import { useLoaderData } from '@remix-run/react';

export async function loader({ request }: LoaderFunctionArgs) {
  const products = await getProducts();

  return json(
    { products },
    {
      headers: {
        'Cache-Control': 'max-age=300, s-maxage=3600', // 5min browser, 1hr CDN
      },
    }
  );
}

export default function ProductsIndex() {
  const { products } = useLoaderData<typeof loader>();

  return (
    <div>
      <h1>Products</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </div>
  );
}

// Optimized product card component
function ProductCard({ product }: { product: Product }) {
  return (
    <div className="product-card">
      <img
        src={product.image}
        alt={product.name}
        width="300"
        height="200"
        loading="lazy"
        decoding="async"
      />
      <h3>{product.name}</h3>
      <p>${product.price}</p>
    </div>
  );
}
```

**Bundle Size Monitoring:**
```typescript
// next.config.js - Bundle analysis
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    bundlePagesRouterDependencies: true,
  },
  webpack: (config, { isServer, dev }) => {
    if (!isServer && !dev) {
      // Bundle size warnings
      config.performance = {
        maxAssetSize: 200000, // 200KB
        maxEntrypointSize: 200000,
        hints: 'error',
      };
    }
    return config;
  },
};

module.exports = nextConfig;

// Bundle analysis script
// scripts/analyze-bundle.js
const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

if (process.env.ANALYZE === 'true') {
  module.exports.webpack = (config) => {
    config.plugins.push(
      new BundleAnalyzerPlugin({
        analyzerMode: 'server',
        openAnalyzer: true,
      })
    );
    return config;
  };
}
```

**CI Performance Gates:**
```yaml
# .github/workflows/performance.yml
name: Performance Standards
on: [pull_request]

jobs:
  performance-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build application
        run: npm run build

      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v10
        with:
          configPath: './lighthouse.config.js'
          uploadArtifacts: true
          temporaryPublicStorage: true
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}

      - name: Bundle Size Check
        run: |
          npm run build:analyze
          node scripts/check-bundle-size.js
```

**Lighthouse Configuration:**
```typescript
// lighthouse.config.ts
module.exports = {
  ci: {
    assert: {
      preset: 'lighthouse:recommended',
      assertions: {
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'first-contentful-paint': ['error', { maxNumericValue: 1800 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 200 }],
        'interactive': ['error', { maxNumericValue: 3500 }],
      },
    },
    collect: {
      numberOfRuns: 3,
      settings: {
        chromeFlags: '--no-sandbox --disable-dev-shm-usage',
      },
    },
  },
};
```

## Examples

```typescript
// ❌ BAD: Client-heavy, unoptimized patterns
'use client';

function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Client-side data fetching (slower, poor SEO)
    fetch('/api/products')
      .then(r => r.json())
      .then(data => {
        setProducts(data);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      {products.map(product => (
        <div key={product.id}>
          {/* Unoptimized images */}
          <img src={product.image} alt={product.name} />
          <h3>{product.name}</h3>
        </div>
      ))}
    </div>
  );
}
```

```typescript
// ✅ GOOD: Server-first, optimized patterns
// Server Component (default)
async function ProductsPage() {
  const products = await getProducts(); // Server-side, faster initial load

  return (
    <div>
      <h1>Products</h1>
      <Suspense fallback={<ProductsSkeleton />}>
        <ProductList products={products} />
      </Suspense>
    </div>
  );
}

function ProductList({ products }: { products: Product[] }) {
  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {products.map(product => (
        <div key={product.id} className="product-card">
          <Image
            src={product.image}
            alt={product.name}
            width={300}
            height={200}
            priority={product.featured}
            sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
          />
          <h3>{product.name}</h3>
          <p>${product.price}</p>
        </div>
      ))}
    </div>
  );
}
```

```typescript
// ❌ BAD: Large client-side bundle
'use client';

import {
  Chart,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'; // Large chart library loaded upfront
import { Line } from 'react-chartjs-2';

Chart.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

function AnalyticsDashboard({ data }: { data: AnalyticsData }) {
  return <Line data={data} />; // 100KB+ JavaScript bundle
}
```

```typescript
// ✅ GOOD: Lazy-loaded client components
'use client';

import { lazy, Suspense } from 'react';

// Lazy load heavy chart library
const AnalyticsChart = lazy(() => import('./AnalyticsChart'));

function AnalyticsDashboard({ data }: { data: AnalyticsData }) {
  return (
    <div>
      <h2>Analytics</h2>
      <Suspense fallback={<ChartSkeleton />}>
        <AnalyticsChart data={data} />
      </Suspense>
    </div>
  );
}
```

## Related Bindings

- [server-first-architecture](server-first-architecture.md): Server-first architecture provides the foundation for performance by default through reduced JavaScript bundle sizes and faster server-side data fetching.

- [performance-testing-standards](../../core/performance-testing-standards.md): General performance testing standards provide the testing infrastructure that validates React performance targets in CI/CD pipelines.

- [react-framework-selection](react-framework-selection.md): Framework selection criteria include performance characteristics as key decision factors for choosing between Next.js and Remix.

- [automated-quality-gates](../../core/automated-quality-gates.md): Performance targets integrate with automated quality gates to prevent performance regressions from reaching production.

- [modern-typescript-toolchain](../typescript/modern-typescript-toolchain.md): TypeScript toolchain enables bundle analysis and type-safe performance monitoring, supporting the measurement and validation of performance standards.

- [quality-metrics-and-monitoring](../../core/quality-metrics-and-monitoring.md): Performance standards require continuous monitoring and metrics collection to ensure targets are maintained in production environments.
