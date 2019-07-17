# pgPerformance

###### Track slow and problem queries such as slowest per total time, slowest per mean time, most frequent queries, long running queries (greater than 1 second long) and all active queries. pgPerformance is made responsively and will resize for any mobile device nicely. It was inspired after a 3 month long internship a Cozy.co tracking slow queries the hard way - tailing the `Postgres.log` file. This app is an aggregation of all queries, for as long as your `pg_stat_statements` and `pg_stat_activity` tables have been loaded; giving better, more accurate information than the `Postgres.log` which is often times machine dependent.  If there are descrepencies or concerns, feel free to contact or open a pull request on it. 
##### By Aleena Watson

### What you need:
* `PostgreSQL` database 
* Load [pg_stat_statements](https://www.postgresql.org/docs/current/static/pgstatstatements.html). This is a crutial step, although you have `Postgres`, `pg_stat_statements` table still needs to be configured in order for the app to work!
* Install `pgPerformance` and enter your database information accordingly in `config.yml` _(see example `.yml` file included)_


### Technology/Gems Used

* _PostgreSQL_
* _Ruby_
* _CSS_
* _HTML_
* _Sinatra_
* _pry_
* _Sequel_
* _Rogue_
* _Configurability_
* _pJax_

### License 
This software is licensed under the [MIT license](LICENSE.txt)


Copyright(c) 2017 Aleena Watson
