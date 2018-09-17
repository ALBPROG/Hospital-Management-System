<?php
$con = mysqli_connect('localhost','id6216490_olti1987','Xhuxhi1987');
if (empty($con)) {
 	echo mysql_error();
 } 
 $data = mysqli_select_db($con,"id6216490_hospital");
 if (empty($data)) {
 	echo mysql_error();
 }
?>