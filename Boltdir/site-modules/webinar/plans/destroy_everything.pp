plan webinar::destroy_everything(
  Array $destroy_targets
){
  $destroy_targets.each |Hash $destroy_target| {run_plan('terraform::destroy', $destroy_target)}
}
