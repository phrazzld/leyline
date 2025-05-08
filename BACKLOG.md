# BACKLOG

- rewrite the tenets and bindings to be natural language first
  - they are used as extra context by large language models -- they do not always need
    to translate so directly to deterministic configurations or actions
- audit source philosophy files and ensure that every principle is properly extracted
  into a tenet or binding
- make language / context specific tenets/bindings more clearly broken up (perhaps with
  subdirectories rather than just file prefixes)
- add chrome browser extension tenets / bindings
- add python tenets / bindings
- add bash tenets / bindings
- add cli tenets / bindings
- add tenets / bindings for the benefit of strongly opinionated design over endless
  configuration
  - is probably a binding tied to the simplicity tenet (at least) because it creates
    better ux and simplifies code if there aren't a gazillion knobs and levers
- stronger storybook tenets / bindings
- add bindings for preferred tools and packages etc
  - pnpm > npm
  - vitest > jest
  - uv > pip
  - playwright > cypress
  - etc
- more opinionated logging tenets/bindings; and really more generally around visibility.
  the best logging in the world is hardly helpful if they're not easy to visualize, if
  there's not clear transparency, if they're not accessible in a direct and actionable
  way. same goes for tests -- we love coverage maps, we love visualizations and
  articulations and various toolings and whatnot that make it clearer what is being
  tested and what is not and so on
