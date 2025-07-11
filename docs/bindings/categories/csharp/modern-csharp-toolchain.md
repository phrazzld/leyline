---
id: modern-csharp-toolchain
last_modified: '2025-07-01'
version: '0.2.0'
derived_from: automation
enforced_by: 'global.json, Directory.Build.props, .editorconfig, CI validation'
---

# Binding: Establish Unified Modern C# Toolchain

Use a standardized, integrated set of modern tools for all C# projects: .NET 8.0+ SDK with SDK-style projects, xUnit for testing, Central Package Management for dependencies, BenchmarkDotNet for performance, and source generators over reflection. Configure these tools consistently using Directory.Build.props with semantic version ranges, and enforce through automated analyzers and CI validation.

## Rationale

This binding implements our automation tenet by eliminating the cognitive overhead and friction of tool selection, configuration, and integration decisions for every C# project. Just as a manufacturing assembly line benefits from standardized, well-integrated equipment, development teams benefit from a unified toolchain that works together seamlessly and becomes second nature to use.

The .NET ecosystem has evolved significantly, but many teams still operate with fragmented tooling approaches—mixing .NET Framework with .NET Core patterns, using various test frameworks across projects, or maintaining inconsistent analyzer configurations. This fragmentation creates exponential complexity: different build patterns, varying package management strategies, incompatible project formats, and fragmented knowledge distribution.

The choice of modern, proven tools over legacy alternatives provides concrete automation benefits: SDK-style projects enable simpler configuration and better cross-platform support, Central Package Management reduces version conflicts, and source generators eliminate runtime reflection overhead. These improvements compound over time—what starts as cleaner project files becomes significantly reduced maintenance burden and more predictable performance characteristics as the solution grows.

## Rule Definition

This rule applies to all C# projects, including ASP.NET Core applications, libraries, console applications, and test projects. The rule specifically requires:

**Unified Tool Selection:**
- **SDK Version**: .NET 8.0 or later exclusively, specified in global.json
- **Project Format**: SDK-style projects only, no legacy .csproj formats
- **Testing**: xUnit as the testing framework for all test types
- **Package Management**: Central Package Management (CPM) for all solutions
- **Performance**: BenchmarkDotNet for performance-critical code measurements
- **Code Generation**: Source generators preferred over runtime reflection

**Configuration Standards:**
- **Solution Root**: Directory.Build.props and Directory.Packages.props at solution root
- **Code Style**: .editorconfig with full analyzer severity configuration
- **Version Specification**: Semantic version ranges with Central Package Management
- **Target Frameworks**: Multi-targeting only when required for library compatibility

**Migration Requirements:**
- New projects must start with .NET 8.0+ and SDK-style format
- Existing projects should migrate to SDK-style format first, then update frameworks
- Migration from packages.config to PackageReference, then to Central Package Management
- Document migration timeline with specific milestones

The rule prohibits new projects targeting .NET Framework, using packages.config, or mixing incompatible tooling patterns within a solution. When exceptions exist for legacy integration, they must be isolated, documented, and include sunset dates.

## Practical Implementation

1. **Solution Initialization**: Start every C# solution with standardized configuration:
   ```json
   // global.json
   {
     "sdk": {
       "version": "8.0.100",
       "rollForward": "latestMinor",
       "allowPrerelease": false
     }
   }
   ```

2. **Central Configuration**: Establish shared configuration at solution root:
   ```xml
   <!-- Directory.Build.props -->
   <Project>
     <PropertyGroup>
       <TargetFramework>net8.0</TargetFramework>
       <LangVersion>12.0</LangVersion>
       <Nullable>enable</Nullable>
       <ImplicitUsings>enable</ImplicitUsings>
       <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
       <EnableNETAnalyzers>true</EnableNETAnalyzers>
       <AnalysisLevel>latest-recommended</AnalysisLevel>
       <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
     </PropertyGroup>
   </Project>

   <!-- Directory.Packages.props -->
   <Project>
     <PropertyGroup>
       <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
       <CentralPackageTransitivePinningEnabled>true</CentralPackageTransitivePinningEnabled>
     </PropertyGroup>
     <ItemGroup>
       <PackageVersion Include="xunit" Version="2.6.0" />
       <PackageVersion Include="xunit.runner.visualstudio" Version="2.5.0" />
       <PackageVersion Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
       <PackageVersion Include="BenchmarkDotNet" Version="0.13.0" />
       <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
     </ItemGroup>
   </Project>
   ```

3. **Code Style Enforcement**: Configure comprehensive analyzer rules:
   ```ini
   # .editorconfig
   root = true

   [*.cs]
   # Language conventions
   dotnet_sort_system_directives_first = true
   csharp_new_line_before_open_brace = all
   csharp_prefer_braces = true:error
   csharp_style_prefer_method_group_conversion = true:warning
   csharp_style_prefer_primary_constructors = true:suggestion

   # Nullability
   dotnet_diagnostic.CS8600.severity = error  # Null assigned to non-nullable
   dotnet_diagnostic.CS8602.severity = error  # Dereference of possibly null
   dotnet_diagnostic.CS8604.severity = error  # Possible null argument

   # Code quality
   dotnet_diagnostic.CA1812.severity = error  # Avoid uninstantiated internal classes
   dotnet_diagnostic.CA1825.severity = warning # Avoid zero-length array allocations
   dotnet_diagnostic.CA2016.severity = error  # Forward CancellationToken
   ```

4. **Testing Standards**: Implement consistent test project structure:
   ```xml
   <Project Sdk="Microsoft.NET.Sdk">
     <PropertyGroup>
       <IsPackable>false</IsPackable>
       <IsTestProject>true</IsTestProject>
     </PropertyGroup>
     <ItemGroup>
       <PackageReference Include="xunit" />
       <PackageReference Include="xunit.runner.visualstudio" />
       <PackageReference Include="Microsoft.NET.Test.Sdk" />
     </ItemGroup>
   </Project>
   ```

5. **Source Generator Integration**: Prefer compile-time code generation:
   ```csharp
   // Use source generators for JSON serialization
   [JsonSerializable(typeof(OrderDto))]
   internal partial class OrderJsonContext : JsonSerializerContext { }

   // Use source generators for DI
   services.AddSingleton<IOrderService, OrderService>();
   // Generated: services.TryAddSingleton<IOrderService>(sp => new OrderService(sp.GetRequiredService<IOrderRepository>()));
   ```

6. **Performance Validation**: Integrate performance benchmarks:
   ```csharp
   [MemoryDiagnoser]
   [SimpleJob(RuntimeMoniker.Net80)]
   public class StringOperationsBenchmark
   {
       [Benchmark]
       public string Concatenation() => string.Concat("Hello", " ", "World");

       [Benchmark]
       public string Interpolation() => $"Hello World";
   }
   ```

## Examples

```xml
<!-- ❌ BAD: Legacy project format with mixed configuration -->
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" DefaultTargets="Build">
  <Import Project="$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props" />
  <PropertyGroup>
    <TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="System" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.1" />
  </ItemGroup>
</Project>

<!-- ✅ GOOD: Modern SDK-style with centralized configuration -->
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" />
  </ItemGroup>
</Project>
```

```csharp
// ❌ BAD: Runtime reflection for configuration
public class AppSettings
{
    public static T GetValue<T>(string key)
    {
        var value = ConfigurationManager.AppSettings[key];
        return (T)Convert.ChangeType(value, typeof(T));
    }
}

// ✅ GOOD: Source-generated strongly-typed configuration
[ConfigurationKeyName("AppSettings")]
public record AppSettings
{
    public required string ConnectionString { get; init; }
    public required int MaxRetries { get; init; }
}
// Source generator creates: services.Configure<AppSettings>(configuration.GetSection("AppSettings"));
```

```csharp
// ❌ BAD: Mixed testing frameworks and patterns
[TestClass]  // MSTest
public class OrderTests
{
    [TestMethod]
    public void TestMethod1() { }
}

[TestFixture]  // NUnit
public class ProductTests
{
    [Test]
    public void Test1() { }
}

// ✅ GOOD: Consistent xUnit with modern patterns
public class OrderTests
{
    [Fact]
    public void CreateOrder_WithValidData_Succeeds()
    {
        // Arrange
        var order = new Order(customerId: 123);

        // Act
        var result = order.AddItem(productId: 456, quantity: 2);

        // Assert
        Assert.True(result.IsSuccess);
    }
}
```

## Related Bindings

- [tooling-investment.md](../core/tooling-investment.md): This toolchain binding implements the principle of mastering a small set of high-impact tools. The .NET SDK, Central Package Management, and consistent analyzer configuration reduce learning overhead across teams.

- [preferred-technology-patterns.md](../core/preferred-technology-patterns.md): This binding applies the "choose boring technology" principle by selecting proven, stable tools (.NET LTS releases, xUnit, established analyzers) while incorporating modern capabilities (source generators, CPM) that provide clear value.

- [immutable-by-default.md](../core/immutable-by-default.md): The emphasis on records, init-only properties, and source generators reinforces immutability patterns at the toolchain level, making immutable code the path of least resistance.

- [automated-quality-gates.md](../core/automated-quality-gates.md): The analyzer configuration and build-time enforcement implement automated quality gates, catching issues during development rather than in code review or production.

- [development-environment-consistency.md](../core/development-environment-consistency.md): The unified toolchain ensures all team members use identical SDK versions, package versions, and analyzer rules across different machines and CI environments.
