The current interface is highly idiomatic. The ontological model has developed
as we added features, while we were also actively using the tool in daily
development.

The following changes need to be made:
* 'work' actions should be merged with 'project'
* individual service controls should be unified under a 'services' component
  * a project may define multiple services
  * each service defines:
    * build <env, def: local>: transpile and check syntax
    * deploy <env, def: local> : deploy and start service for indicated
      environment
    * stop <env, def: local> : stop running service for indicated environment
  * a library is just another service
