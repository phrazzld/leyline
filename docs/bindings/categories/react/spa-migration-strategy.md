---
id: spa-migration-strategy
last_modified: '2025-01-10'
version: '0.2.0'
derived_from: simplicity
enforced_by: 'Migration checklists, Performance monitoring, Code review'
---

# Binding: SPA-to-Meta-Framework Migration Strategy

Migrate React SPAs to meta-frameworks using component-by-component incremental adoption with hybrid coexistence architecture. Establish clear migration phases, maintain performance standards, and ensure zero-downtime deployment throughout the transition process.

## Rationale

This binding implements our simplicity tenet by eliminating the complexity and risk of big-bang migrations. Traditional SPA-to-meta-framework migrations often fail due to their all-or-nothing approach, leading to extended development freezes, performance regressions, and increased bug surface area.

Component-by-component migration allows teams to incrementally adopt meta-framework patterns while maintaining existing SPA functionality. This approach reduces risk, enables continuous value delivery, and provides multiple rollback points throughout the migration process.

The hybrid coexistence architecture ensures that SPA and meta-framework components can run together seamlessly during the transition period. This eliminates the need for complete architectural rewrites and allows teams to migrate at their own pace while maintaining feature development velocity.

## Rule Definition

This rule applies to all React SPA applications migrating to Next.js App Router or Remix. The rule specifically requires:

**Migration Phases:**
- **Phase 1**: Coexistence setup - establish hybrid architecture
- **Phase 2**: Leaf component migration - components with no dependencies
- **Phase 3**: Parent component migration - components with child dependencies
- **Phase 4**: Route and state migration - routing and global state patterns
- **Phase 5**: SPA removal - clean up legacy SPA infrastructure

**Incremental Requirements:**
- **Component-by-component**: Migrate individual components, not entire routes
- **Backwards compatibility**: Maintain existing SPA functionality during migration
- **Performance monitoring**: Track Core Web Vitals during migration
- **Rollback capability**: Ability to revert any migrated component within 24 hours

**Risk Mitigation:**
- **Feature flag protection**: All migrated components behind feature flags
- **A/B testing**: Gradual rollout of migrated components
- **Performance gates**: Automated rollback on performance regression
- **Zero-downtime**: Migration must not interrupt user experience

## Practical Implementation

**Phase 1: Coexistence Architecture Setup**

```typescript
// migration-config.ts
interface MigrationConfig {
  enabledComponents: string[];
  enabledRoutes: string[];
  performanceThresholds: {
    LCP: number;
    FID: number;
    CLS: number;
  };
  rollbackTriggers: {
    errorRate: number;
    performanceRegression: number;
  };
}

const migrationConfig: MigrationConfig = {
  enabledComponents: ['UserProfile', 'ProductCard'],
  enabledRoutes: ['/dashboard'],
  performanceThresholds: {
    LCP: 2500,
    FID: 100,
    CLS: 0.1
  },
  rollbackTriggers: {
    errorRate: 0.05,
    performanceRegression: 0.2
  }
};
```

**Hybrid Router Setup:**
```typescript
// hybrid-router.tsx
import { BrowserRouter } from 'react-router-dom';
import { useFeatureFlag } from './feature-flags';

interface HybridRouterProps {
  children: React.ReactNode;
}

function HybridRouter({ children }: HybridRouterProps) {
  const isMetaFrameworkEnabled = useFeatureFlag('meta-framework-routing');

  if (isMetaFrameworkEnabled) {
    // Use meta-framework routing for enabled routes
    return <MetaFrameworkRouter>{children}</MetaFrameworkRouter>;
  }

  // Fall back to SPA routing
  return <BrowserRouter>{children}</BrowserRouter>;
}

// Route-level coexistence
function DashboardRoute() {
  const useMigratedDashboard = useFeatureFlag('migrated-dashboard');

  if (useMigratedDashboard) {
    return <MigratedDashboard />;
  }

  return <LegacyDashboard />;
}
```

**Phase 2: Leaf Component Migration**

```typescript
// component-migrator.tsx
interface ComponentMigrationWrapper<T> {
  legacyComponent: React.ComponentType<T>;
  migratedComponent: React.ComponentType<T>;
  migrationKey: string;
}

function createMigratedComponent<T>({
  legacyComponent: LegacyComponent,
  migratedComponent: MigratedComponent,
  migrationKey
}: ComponentMigrationWrapper<T>): React.ComponentType<T> {

  return function HybridComponent(props: T) {
    const isMigrated = useFeatureFlag(migrationKey);
    const performanceMonitor = usePerformanceMonitor();

    // Performance monitoring wrapper
    const ComponentToRender = isMigrated ? MigratedComponent : LegacyComponent;

    return (
      <PerformanceMonitor
        componentName={migrationKey}
        onPerformanceIssue={(metrics) => {
          if (metrics.LCP > 2500) {
            rollbackComponent(migrationKey);
          }
        }}
      >
        <ComponentToRender {...props} />
      </PerformanceMonitor>
    );
  };
}

// Usage example
const ProductCard = createMigratedComponent({
  legacyComponent: LegacyProductCard,
  migratedComponent: MigratedProductCard,
  migrationKey: 'product-card-migration'
});
```

**State Bridge Pattern:**
```typescript
// state-bridge.tsx
interface StateBridge {
  // SPA state (Redux/Zustand)
  legacyState: any;
  // Meta-framework state (Server Components/loaders)
  migratedState: any;
  // Sync mechanism
  syncState: (key: string, value: any) => void;
}

function useStateBridge(): StateBridge {
  const legacyState = useSelector(state => state);
  const migratedState = useServerState();

  const syncState = useCallback((key: string, value: any) => {
    // Update both state systems during migration
    dispatch(updateLegacyState(key, value));
    updateServerState(key, value);
  }, []);

  return {
    legacyState,
    migratedState,
    syncState
  };
}

// Component using state bridge
function UserProfile() {
  const { legacyState, migratedState, syncState } = useStateBridge();
  const isMigrated = useFeatureFlag('user-profile-migration');

  const user = isMigrated ? migratedState.user : legacyState.user;

  const updateUser = (updates: Partial<User>) => {
    syncState('user', { ...user, ...updates });
  };

  return (
    <div>
      <h1>{user.name}</h1>
      <button onClick={() => updateUser({ name: 'New Name' })}>
        Update Name
      </button>
    </div>
  );
}
```

**Phase 3: Parent Component Migration**

```typescript
// parent-component-migration.tsx
interface MigrationDependency {
  componentName: string;
  isMigrated: boolean;
  dependencies: string[];
}

function checkMigrationEligibility(
  componentName: string,
  dependencies: MigrationDependency[]
): boolean {
  const component = dependencies.find(dep => dep.componentName === componentName);

  if (!component) return false;

  // All dependencies must be migrated first
  return component.dependencies.every(depName => {
    const dep = dependencies.find(d => d.componentName === depName);
    return dep?.isMigrated || false;
  });
}

// Migration orchestrator
function MigrationOrchestrator() {
  const migrationPlan: MigrationDependency[] = [
    {
      componentName: 'UserProfile',
      isMigrated: true,
      dependencies: []
    },
    {
      componentName: 'ProductCard',
      isMigrated: true,
      dependencies: []
    },
    {
      componentName: 'ProductList',
      isMigrated: false,
      dependencies: ['ProductCard']
    },
    {
      componentName: 'Dashboard',
      isMigrated: false,
      dependencies: ['UserProfile', 'ProductList']
    }
  ];

  const eligibleComponents = migrationPlan.filter(component =>
    !component.isMigrated &&
    checkMigrationEligibility(component.componentName, migrationPlan)
  );

  return (
    <div>
      <h2>Ready for Migration:</h2>
      {eligibleComponents.map(component => (
        <MigrationCandidate
          key={component.componentName}
          component={component}
        />
      ))}
    </div>
  );
}
```

**Phase 4: Route and State Migration**

```typescript
// route-migration.tsx
interface RouteConfig {
  path: string;
  isMigrated: boolean;
  component: React.ComponentType;
  dependencies: string[];
}

function RouteManager() {
  const routes: RouteConfig[] = [
    {
      path: '/profile',
      isMigrated: true,
      component: MigratedUserProfile,
      dependencies: ['UserProfile']
    },
    {
      path: '/dashboard',
      isMigrated: false,
      component: LegacyDashboard,
      dependencies: ['UserProfile', 'ProductList']
    }
  ];

  return (
    <Routes>
      {routes.map(route => (
        <Route
          key={route.path}
          path={route.path}
          element={
            route.isMigrated ? (
              <MetaFrameworkRoute>
                <route.component />
              </MetaFrameworkRoute>
            ) : (
              <SPARoute>
                <route.component />
              </SPARoute>
            )
          }
        />
      ))}
    </Routes>
  );
}
```

**Performance Monitoring and Rollback:**
```typescript
// performance-monitor.tsx
interface PerformanceMetrics {
  LCP: number;
  FID: number;
  CLS: number;
  errorRate: number;
}

function usePerformanceMonitor(componentName: string) {
  const [metrics, setMetrics] = useState<PerformanceMetrics | null>(null);

  useEffect(() => {
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();

      const lcp = entries.find(entry => entry.entryType === 'largest-contentful-paint');
      const fid = entries.find(entry => entry.entryType === 'first-input');
      const cls = entries.find(entry => entry.entryType === 'layout-shift');

      const currentMetrics: PerformanceMetrics = {
        LCP: lcp?.startTime || 0,
        FID: fid?.processingStart - fid?.startTime || 0,
        CLS: cls?.value || 0,
        errorRate: getErrorRate(componentName)
      };

      setMetrics(currentMetrics);

      // Automatic rollback on performance regression
      if (shouldRollback(currentMetrics, componentName)) {
        rollbackComponent(componentName);
      }
    });

    observer.observe({ entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift'] });

    return () => observer.disconnect();
  }, [componentName]);

  return metrics;
}

async function rollbackComponent(componentName: string) {
  // Disable feature flag
  await disableFeatureFlag(`${componentName}-migration`);

  // Log rollback event
  console.warn(`Rolled back ${componentName} due to performance regression`);

  // Notify monitoring system
  sendTelemetry('component-rollback', {
    componentName,
    timestamp: new Date().toISOString(),
    reason: 'performance-regression'
  });
}
```

**Phase 5: SPA Removal**

```typescript
// cleanup-orchestrator.tsx
interface CleanupTask {
  name: string;
  priority: 'high' | 'medium' | 'low';
  execute: () => Promise<void>;
  rollback: () => Promise<void>;
}

const cleanupTasks: CleanupTask[] = [
  {
    name: 'Remove SPA Router',
    priority: 'high',
    execute: async () => {
      // Remove react-router-dom dependencies
      // Update routing configuration
    },
    rollback: async () => {
      // Restore SPA routing
    }
  },
  {
    name: 'Remove Legacy State Management',
    priority: 'medium',
    execute: async () => {
      // Remove Redux/Zustand stores
      // Clean up state bridge
    },
    rollback: async () => {
      // Restore legacy state management
    }
  },
  {
    name: 'Remove Build Configuration',
    priority: 'low',
    execute: async () => {
      // Update webpack/vite configuration
      // Remove SPA-specific build steps
    },
    rollback: async () => {
      // Restore build configuration
    }
  }
];

function CleanupOrchestrator() {
  const executeCleanup = async () => {
    // Execute high-priority tasks first
    const sortedTasks = cleanupTasks.sort((a, b) => {
      const priorityOrder = { high: 3, medium: 2, low: 1 };
      return priorityOrder[b.priority] - priorityOrder[a.priority];
    });

    for (const task of sortedTasks) {
      try {
        await task.execute();
        console.log(`✓ Completed: ${task.name}`);
      } catch (error) {
        console.error(`✗ Failed: ${task.name}`, error);
        await task.rollback();
      }
    }
  };

  return (
    <div>
      <h2>Migration Cleanup</h2>
      <button onClick={executeCleanup}>
        Execute Cleanup Tasks
      </button>
    </div>
  );
}
```

## Examples

```typescript
// ❌ BAD: Big-bang migration approach
// Attempt to migrate entire application at once
function MigrateEverything() {
  // Replace entire SPA with meta-framework
  // High risk, no rollback capability
  // Blocks feature development for months

  return (
    <NextApp>
      {/* All components migrated simultaneously */}
      <MigratedHeader />
      <MigratedNavigation />
      <MigratedDashboard />
      <MigratedFooter />
    </NextApp>
  );
}
```

```typescript
// ✅ GOOD: Component-by-component migration
function IncrementalMigration() {
  return (
    <div>
      {/* Hybrid approach with feature flags */}
      <ConditionalComponent
        legacy={<LegacyHeader />}
        migrated={<MigratedHeader />}
        migrationKey="header-migration"
      />

      <ConditionalComponent
        legacy={<LegacyNavigation />}
        migrated={<MigratedNavigation />}
        migrationKey="navigation-migration"
      />

      {/* Some components still legacy */}
      <LegacyDashboard />
      <LegacyFooter />
    </div>
  );
}
```

```typescript
// ❌ BAD: No state synchronization during migration
function BrokenStateMigration() {
  const legacyUser = useSelector(state => state.user);
  const migratedUser = useServerState().user;

  // State is out of sync between architectures
  // Updates to legacy state don't reflect in migrated components
  // Creates inconsistent user experience

  return (
    <div>
      <LegacyUserProfile user={legacyUser} />
      <MigratedUserSettings user={migratedUser} />
    </div>
  );
}
```

```typescript
// ✅ GOOD: State bridge pattern maintains consistency
function ConsistentStateMigration() {
  const { getUser, updateUser } = useStateBridge();

  // Single source of truth during migration
  const user = getUser();

  const handleUserUpdate = (updates: Partial<User>) => {
    // Updates both legacy and migrated state
    updateUser(updates);
  };

  return (
    <div>
      <ConditionalComponent
        legacy={<LegacyUserProfile user={user} onUpdate={handleUserUpdate} />}
        migrated={<MigratedUserProfile user={user} onUpdate={handleUserUpdate} />}
        migrationKey="user-profile-migration"
      />
    </div>
  );
}
```

```typescript
// ❌ BAD: No performance monitoring during migration
function UnmonitoredMigration() {
  const isMigrated = useFeatureFlag('component-migration');

  // No visibility into performance impact
  // No automatic rollback on regression
  // Users experience performance issues

  return isMigrated ? <MigratedComponent /> : <LegacyComponent />;
}
```

```typescript
// ✅ GOOD: Performance monitoring with automatic rollback
function MonitoredMigration() {
  const isMigrated = useFeatureFlag('component-migration');
  const performanceMetrics = usePerformanceMonitor('component-migration');

  // Monitor performance during migration
  useEffect(() => {
    if (performanceMetrics && performanceMetrics.LCP > 2500) {
      // Automatic rollback on performance regression
      rollbackComponent('component-migration');
    }
  }, [performanceMetrics]);

  return (
    <PerformanceMonitor componentName="component-migration">
      {isMigrated ? <MigratedComponent /> : <LegacyComponent />}
    </PerformanceMonitor>
  );
}
```

## Related Bindings

- [simplicity](../../tenets/simplicity.md): SPA migration strategy eliminates big-bang complexity by providing clear, incremental migration phases that reduce risk and maintain development velocity.

- [react-framework-selection](react-framework-selection.md): Migration strategy builds on framework selection by providing migration paths specific to Next.js App Router and Remix patterns.

- [server-first-architecture](server-first-architecture.md): Migration strategy transforms client-first SPA patterns into server-first meta-framework patterns through incremental component migration.

- [react-routing-patterns](react-routing-patterns.md): Migration strategy includes specific patterns for migrating SPA routing to meta-framework file-based routing with type safety.

- [incremental-delivery](../../core/incremental-delivery.md): Migration strategy follows incremental delivery principles with small, reversible changes and continuous deployment throughout the migration process.

- [continuous-refactoring](../../core/continuous-refactoring.md): Migration strategy applies continuous refactoring principles by improving code quality incrementally rather than through large, disruptive rewrites.

- [modern-typescript-toolchain](../typescript/modern-typescript-toolchain.md): SPA migration requires consistent TypeScript tooling to maintain type safety while transitioning between different application architectures.

- [quality-metrics-and-monitoring](../../core/quality-metrics-and-monitoring.md): Migration strategy requires comprehensive monitoring to track performance, errors, and user experience throughout the migration process.

- [input-validation-standards](../security/input-validation-standards.md): SPA migration must maintain security standards for input validation as components transition from client-side to server-side execution.
