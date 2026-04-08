# =============================================================================
# Tests: enable_autoscaling resource creation behavior
#
# PR Change: Worker nodes now use a conditional for enable_autoscaling:
#   var.k8s_worker_instance_group_size > 0 ? var.enable_autoscaling : false
#
# The conditional is evaluated in the calling environment (prod/compute.tf)
# before being passed into this module. These module-level tests verify that
# the module correctly creates/omits the autoscaler based on the value it
# receives, validating the downstream behavior of that conditional.
#
# Tests:
#   1. enable_autoscaling=true  → google_compute_autoscaler is created (count=1)
#   2. enable_autoscaling=false → google_compute_autoscaler is NOT created (count=0)
#   3. enable_autoscaling=true with cpu_target=0.7 → CPU policy is applied
#   4. Boundary: min_replicas=1 (minimum valid value)
# =============================================================================

mock_provider "google" {}

# ---------------------------------------------------------------------------
# Test 1: enable_autoscaling=true creates exactly one autoscaler resource.
# ---------------------------------------------------------------------------
run "autoscaler_created_when_autoscaling_enabled" {
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
    condition     = length(google_compute_autoscaler.autoscaler) == 1
    error_message = "Exactly one autoscaler should be created when enable_autoscaling is true."
  }

  assert {
    condition     = google_compute_autoscaler.autoscaler[0].autoscaling_policy[0].min_replicas == 2
    error_message = "Autoscaler min_replicas should match autoscaling_min_replicas variable."
  }

  assert {
    condition     = google_compute_autoscaler.autoscaler[0].autoscaling_policy[0].max_replicas == 5
    error_message = "Autoscaler max_replicas should match autoscaling_max_replicas variable."
  }
}

# ---------------------------------------------------------------------------
# Test 2: enable_autoscaling=false creates NO autoscaler.
# This is the value produced when k8s_worker_instance_group_size == 0,
# because the conditional forces enable_autoscaling to false.
# Also mirrors the permanent behavior of k8s_master_nodes.
# ---------------------------------------------------------------------------
run "autoscaler_not_created_when_autoscaling_disabled" {
  command = plan

  variables {
    name_prefix              = "test-workers-empty"
    network                  = "projects/test-project/global/networks/test-vpc"
    subnetwork               = "projects/test-project/regions/asia-northeast3/subnetworks/test-subnet"
    create_instance_template = true
    create_instance_group    = true
    instance_group_zone      = "asia-northeast3-a"
    instance_group_target_size = 0
    update_policy_type       = "OPPORTUNISTIC"
    # The conditional in prod/compute.tf resolves to false when target_size == 0.
    # Here we pass false directly to test the module-level behavior.
    enable_autoscaling       = false
  }

  assert {
    condition     = length(google_compute_autoscaler.autoscaler) == 0
    error_message = "No autoscaler should be created when enable_autoscaling is false (as when group size is 0)."
  }
}

# ---------------------------------------------------------------------------
# Test 3: CPU utilization target of 0.7 is applied when autoscaling is on.
# Worker nodes use autoscaling_cpu_target = 0.7 (hardcoded in compute.tf).
# ---------------------------------------------------------------------------
run "autoscaler_cpu_target_applied_at_0_7" {
  command = plan

  variables {
    name_prefix              = "test-workers-cpu"
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
    condition     = google_compute_autoscaler.autoscaler[0].autoscaling_policy[0].cpu_utilization[0].target == 0.7
    error_message = "CPU utilization target should be 0.7 as configured in compute.tf."
  }
}

# ---------------------------------------------------------------------------
# Test 4: Boundary — minimum valid non-zero group size (size=1) with
# autoscaling enabled results in autoscaler being created.
# This corresponds to the boundary of the conditional expression (size > 0).
# ---------------------------------------------------------------------------
run "autoscaler_created_at_minimum_nonzero_group_size" {
  command = plan

  variables {
    name_prefix              = "test-workers-single"
    network                  = "projects/test-project/global/networks/test-vpc"
    subnetwork               = "projects/test-project/regions/asia-northeast3/subnetworks/test-subnet"
    create_instance_template = true
    create_instance_group    = true
    instance_group_zone      = "asia-northeast3-a"
    instance_group_target_size = 1
    update_policy_type       = "OPPORTUNISTIC"
    enable_autoscaling       = true
    autoscaling_min_replicas = 1
    autoscaling_max_replicas = 5
    autoscaling_cpu_target   = 0.7
  }

  assert {
    condition     = length(google_compute_autoscaler.autoscaler) == 1
    error_message = "Autoscaler should be created for minimum non-zero group size (size=1)."
  }
}

# ---------------------------------------------------------------------------
# Test 5: Master node configuration — autoscaling hardcoded to false,
# update_policy_type = "OPPORTUNISTIC". No autoscaler regardless of group size.
# Regression test: master nodes must never get an autoscaler.
# ---------------------------------------------------------------------------
run "master_nodes_never_have_autoscaler" {
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
    enable_autoscaling       = false   # Master nodes: always false
  }

  assert {
    condition     = length(google_compute_autoscaler.autoscaler) == 0
    error_message = "Master nodes must never have an autoscaler (enable_autoscaling is hardcoded to false)."
  }

  assert {
    condition     = google_compute_instance_group_manager.instance_group[0].update_policy[0].type == "OPPORTUNISTIC"
    error_message = "Master node MIG must use OPPORTUNISTIC update policy."
  }
}