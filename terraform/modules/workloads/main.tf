# Reads the planted gotcha YAMLs (local file parse - no cluster connection needed here)
# and, when enabled, applies each document at apply time via the kubectl provider.
data "kubectl_path_documents" "gotchas" {
  pattern = "${var.manifests_path}/*.yaml"
}

resource "kubectl_manifest" "gotchas" {
  for_each  = var.enable_planted_gotchas ? toset(data.kubectl_path_documents.gotchas.documents) : toset([])
  yaml_body = each.value

  # The namespace document must land before the objects inside it; server-side apply
  # retries handle most ordering, but keep applies serialized to reduce races.
  wait = true
}
