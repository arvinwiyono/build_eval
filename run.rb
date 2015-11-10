require 'build_eval'

jenkins_monitor = BuildEval.server(
    type: :Jenkins,
    uri: 'https://dev-idam-jenkins.cse.dev.myob.com',
    username: 'jenkins',
    password: 'password1'
).monitor('master_build_packages', 'identityserver_performance_testing', 'master_deploy_identityserver_sit')

loop do
	results = jenkins_monitor.evaluate
	# Determine the overall status
	#light.send(results.status.to_sym)

	# Describes the results of all builds
	puts results.to_s
	puts results.status.to_sym
end