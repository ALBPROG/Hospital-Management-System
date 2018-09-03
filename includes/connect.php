<?php
$con = mysqli_connect('localhost','root','');
if (empty($con)) {
 	echo mysql_error();
 } 
 $data = mysqli_select_db($con,"hospital");
 if (empty($data)) {
 	echo mysql_error();
 }
?>