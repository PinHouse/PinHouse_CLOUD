# =============================================================================
# Tests: update_policy_type = "OPPORTUNISTIC"
#
# PR Change: Both master and worker node module calls now explicitly set
# update_policy_type = "OPPORTUNISTIC" (previously used the default "PROACTIVE").
#
# These tests verify that:
#   1. The compute module correctly propagates update_policy_type to the MIG.
#   2. OPPORTUNISTIC is accepted as a valid value (no validation error).
#   3. The default value "PROACTIVE" still works (regression check).
#   4. Boundary: switching from default PROACTIVE to OPPORTUNISTIC is safe.
# =============================================================================

mock_provider "google" {}

# ---------------------------------------------------------------------------
# Test 1: update_policy_type = "OPPORTUNISTIC" is accepted and plan succeeds.
# This mirrors what both k8s_master_nodes and k8s_worker_nodes now use.
# ---------------------------------------------------------------------------
run "update_policy_type_opportunistic_is_accepted" {
  command = plan

  variables {
    name_prefix              = "test-prefix"
    network                  = "projects/test-project/global/networks/test-vpc"
    subnetwork               = "projects/test-project/regions/asia-northeast3/subnetworks/test-subnet"
    create_instance_template = true
    create_instance_group    = true
    instance_group_zone      = "asia-northeast3-a"
    instance_group_target_size = 1
    update_policy_type       = "OPPORTUNISTIC"
    enable_autoscaling       = false
  }

  assert {
    condition     = google_compute_instance_group_manager.instance_group[0].update_policy[0].type == "OPPORTUNISTIC"
    error_message = "Expected update_policy_type to be OPPORTUNISTIC but got a different value."
  }
}

# ---------------------------------------------------------------------------
# Test 2: update_policy_type defaults to "PROACTIVE" when not specified.
# Regression test to ensure the default is preserved for other callers.
# ---------------------------------------------------------------------------
run "update_policy_type_defaults_to_proactive" {
  command = plan

  variables {
    name_prefix              = "test-prefix"
    network                  = "projects/test-project/global/networks/test-vpc"
    subnetwork               = "projects/test-project/regions/asia-northeast3/subnetworks/test-subnet"
    create_instance_template = true
    create_instance_group    = true
    instance_group_zone      = "asia-northeast3-a"
    instance_group_target_size = 1
    # update_policy_type not set — should default to "PROACTIVE"
    enable_autoscaling       = false
  }

  assert {
    condition     = google_compute_instance_group_manager.instance_group[0].update_policy[0].type == "PROACTIVE"
    error_message = "Expected default update_policy_type to be PROACTIVE."
  }
}

# ---------------------------------------------------------------------------
# Test 3: OPPORTUNISTIC update policy with autoscaling enabled.
# Mirrors the k8s_worker_nodes configuration: OPPORTUNISTIC + autoscaling.
# ---------------------------------------------------------------------------
run "update_policy_opportunistic_with_autoscaling_enabled" {
  command = plan

  variables {
    name_prefix              = "test-workers"
    network                  = "projects/test-project/global/networks/test-vpc"
    subnetwork               = "projects/test-project/regions/asia-northeast3/subnetworks/test-subnet"
    create_instance_template = true
    create_instance_group    = true
    instance_group_zone      = "asia-northeast3-a"
    instance_group_target_size = 2
    update_policy_type       = "OPPORTUNISTIC"
    enable_autoscaling       = true
    autoscaling_min_replicas = 2
    autoscaling_max_replicas = 5
    autoscaling_cpu_target   = 0.7
  }

  assert {
    condition     = google_compute_instance_group_manager.instance_group[0].update_policy[0].type == "OPPORTUNISTIC"
    error_message = "Worker node MIG should use OPPORTUNISTIC update policy."
  }

  assert {
    condition     = length(google_compute_autoscaler.autoscaler) == 1
    error_message = "Autoscaler should be created when enable_autoscaling is true."
  }
}

# ---------------------------------------------------------------------------
# Test 4: OPPORTUNISTIC update policy with autoscaling disabled.
# Mirrors the k8s_master_nodes configuration: OPPORTUNISTIC + no autoscaling.
# ---------------------------------------------------------------------------
run "update_policy_opportunistic_with_autoscaling_disabled" {
  command = plan

  variables {
    name_prefix              = "test-masters"
    network                  = "projects/test-project/global/networks/test-vpc"
    subnetwork               = "projects/test-project/regions/asia-northeast3/subnetworks/test-subnet"
    create_instance_template = true
    create_instance_group    = true
    instance_group_zone      = "asia-northeast3-a"
    instance_group_target_size = 1
    update_policy_type       = "OPPORTUNISTIC"
    enable_autoscaling       = false
  }

  assert {
    condition     = google_compute_instance_group_manager.instance_group[0].update_policy[0].type == "OPPORTUNISTIC"
    error_message = "Master node MIG should use OPPORTUNISTIC update policy."
  }

  assert {
    condition     = length(google_compute_autoscaler.autoscaler) == 0
    error_message = "No autoscaler should be created when enable_autoscaling is false."
  }
}