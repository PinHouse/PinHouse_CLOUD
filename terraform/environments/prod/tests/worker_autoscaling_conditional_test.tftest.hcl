# =============================================================================
# Tests: Worker node autoscaling conditional expression
#
# PR Change (prod/compute.tf, module "k8s_worker_nodes"):
#
#   Before:
#     enable_autoscaling = var.enable_autoscaling
#
#   After:
#     enable_autoscaling = var.k8s_worker_instance_group_size > 0 ? var.enable_autoscaling : false
#
# Intent: When the worker MIG target_size is 0 (fully drained), the autoscaler
# must be disabled unconditionally so GCP does not fight the deliberately-empty
# group. The autoscaler_id output is null when no autoscaler is created.
#
# Tests:
#   1. size > 0, enable_autoscaling=true  → autoscaler_id is non-null
#   2. size > 0, enable_autoscaling=false → autoscaler_id is null
#   3. size = 0, enable_autoscaling=true  → autoscaler_id is null (conditional override)
#   4. size = 0, enable_autoscaling=false → autoscaler_id is null
#   5. size = 1 (boundary), enable_autoscaling=true → autoscaler_id is non-null
#   6. Master nodes: autoscaler_id always null (hardcoded enable_autoscaling=false)
# =============================================================================

mock_provider "google" {}

# ---------------------------------------------------------------------------
# Test 1: Normal operation — workers with size > 0 and autoscaling enabled.
# The conditional passes var.enable_autoscaling through: true → true.
# autoscaler_id should be a non-null string (resource was created).
# ---------------------------------------------------------------------------
run "worker_autoscaling_enabled_when_group_size_positive" {
  command = plan

  variables {
    k8s_worker_instance_group_size = 2
    enable_autoscaling             = true
    autoscaling_min_replicas       = 2
    autoscaling_max_replicas       = 5

    service_account_email = "sa@test-project.iam.gserviceaccount.com"
  }

  # size(2) > 0 and enable_autoscaling=true → conditional evaluates to true → autoscaler created
  assert {
    condition     = module.k8s_worker_nodes.autoscaler_id != null
    error_message = "Worker autoscaler must be created when group size > 0 and enable_autoscaling = true."
  }
}

# ---------------------------------------------------------------------------
# Test 2: Workers with size > 0 but autoscaling explicitly disabled.
# The conditional passes var.enable_autoscaling through: false → false.
# autoscaler_id should be null.
# ---------------------------------------------------------------------------
run "worker_autoscaling_disabled_when_group_size_positive_but_autoscaling_false" {
  command = plan

  variables {
    k8s_worker_instance_group_size = 2
    enable_autoscaling             = false
    autoscaling_min_replicas       = 2
    autoscaling_max_replicas       = 5

    service_account_email = "sa@test-project.iam.gserviceaccount.com"
  }

  # size(2) > 0 but enable_autoscaling=false → conditional evaluates to false → no autoscaler
  assert {
    condition     = module.k8s_worker_nodes.autoscaler_id == null
    error_message = "Worker autoscaler must not be created when enable_autoscaling = false, even with positive group size."
  }
}

# ---------------------------------------------------------------------------
# Test 3 (KEY NEW BEHAVIOR): Workers with size = 0 and enable_autoscaling=true.
# The conditional overrides enable_autoscaling to false, preventing the
# autoscaler from conflicting with a deliberately-empty MIG.
# autoscaler_id should be null despite enable_autoscaling=true.
# ---------------------------------------------------------------------------
run "worker_autoscaling_forced_false_when_group_size_is_zero" {
  command = plan

  variables {
    k8s_worker_instance_group_size = 0
    enable_autoscaling             = true    # user flag is true, but group is empty
    autoscaling_min_replicas       = 2
    autoscaling_max_replicas       = 5

    service_account_email = "sa@test-project.iam.gserviceaccount.com"
  }

  # size(0) is NOT > 0 → conditional resolves to false → no autoscaler created
  assert {
    condition     = module.k8s_worker_nodes.autoscaler_id == null
    error_message = "Worker autoscaler must be suppressed when group size is 0, regardless of enable_autoscaling value."
  }
}

# ---------------------------------------------------------------------------
# Test 4: Workers with size = 0 and enable_autoscaling = false.
# Both the explicit value and the conditional produce false; autoscaler_id null.
# ---------------------------------------------------------------------------
run "worker_autoscaling_null_when_group_size_zero_and_autoscaling_false" {
  command = plan

  variables {
    k8s_worker_instance_group_size = 0
    enable_autoscaling             = false
    autoscaling_min_replicas       = 2
    autoscaling_max_replicas       = 5

    service_account_email = "sa@test-project.iam.gserviceaccount.com"
  }

  assert {
    condition     = module.k8s_worker_nodes.autoscaler_id == null
    error_message = "No autoscaler when group size is 0 and enable_autoscaling is false."
  }
}

# ---------------------------------------------------------------------------
# Test 5: Boundary — size = 1 is the minimum value for the conditional to
# evaluate to true (size > 0). Autoscaling should be enabled.
# ---------------------------------------------------------------------------
run "worker_autoscaling_enabled_at_minimum_nonzero_boundary" {
  command = plan

  variables {
    k8s_worker_instance_group_size = 1    # boundary: exactly one instance
    enable_autoscaling             = true
    autoscaling_min_replicas       = 1
    autoscaling_max_replicas       = 5

    service_account_email = "sa@test-project.iam.gserviceaccount.com"
  }

  # size(1) > 0 and enable_autoscaling=true → conditional evaluates to true
  assert {
    condition     = module.k8s_worker_nodes.autoscaler_id != null
    error_message = "Autoscaler should be created when group size is exactly 1 (minimum non-zero boundary)."
  }
}

# ---------------------------------------------------------------------------
# Test 6: Master nodes always have enable_autoscaling = false (hardcoded).
# Regression: The PR did not change the master node autoscaling policy.
# Master autoscaler_id must remain null even when enable_autoscaling=true globally.
# ---------------------------------------------------------------------------
run "master_autoscaling_always_disabled_regardless_of_global_enable_autoscaling" {
  command = plan

  variables {
    k8s_master_instance_group_size = 1
    enable_autoscaling             = true    # global flag is true, but masters ignore it
    k8s_worker_instance_group_size = 2

    service_account_email = "sa@test-project.iam.gserviceaccount.com"
  }

  # Master nodes have enable_autoscaling = false hardcoded in compute.tf → no autoscaler
  assert {
    condition     = module.k8s_master_nodes.autoscaler_id == null
    error_message = "Master nodes must never have an autoscaler; enable_autoscaling is hardcoded to false in compute.tf."
  }
}