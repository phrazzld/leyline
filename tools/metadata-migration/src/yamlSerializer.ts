/**
 * YamlSerializer module for converting StandardYamlMetadata to YAML string format.
 * Provides consistent YAML formatting for metadata front-matter.
 */

import yaml from "js-yaml";
import { StandardYamlMetadata } from "./types.js";

/**
 * Converts StandardYamlMetadata object to a YAML string.
 * Produces consistent formatting suitable for front-matter blocks.
 *
 * @param metadata - The metadata object to serialize
 * @returns YAML formatted string
 */
export function serializeToYaml(metadata: StandardYamlMetadata): string {
  return yaml.dump(metadata, {
    indent: 2,
    lineWidth: 80,
    noRefs: true,
    quotingType: '"',
    forceQuotes: false,
    sortKeys: false,
  });
}
