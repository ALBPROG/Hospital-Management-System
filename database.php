<?php
$url = parse_url(getenv("CLEARDB_DATABASE_URL"));

$server = $url["host"];
$username = $url["user"];
$password = $url["pass"];
$db = substr($url["path"], 1);

$conn = new mysqli($server, $username, $password, $db);



$active_group = 'default';
$active_record = TRUE;

$db['default'] = array(
'dsn' -> '',    
'hostname' => 'us-cdbr-iron-east-01.cleardb.net',
'username' => 'bd3d73e2577610',
'password' => 'c1908ccb',
'database' => 'heroku_6bb251ec81a20d6',
'dbdriver' => 'mysqli',
'dbprefix' => '',
'pconnect' => FALSE,
'db_debug' => (ENVIRONMENT !== 'production'),
'cache_on' => FALSE,
'cachedir' => '',
'char_set' => 'utf8',
'dbcollat' => 'utf8_general_ci',
'swap_pre' => '',
'encrypt'  => FALSE,
'compress' => FALSE,
'stricton' => FALSE,
'failover' => array(),
'save_queries' => TRUE

);

?>