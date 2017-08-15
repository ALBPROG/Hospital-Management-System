<?php
session_start();
if (!empty($_SESSION['admin'])&&!empty($_SESSION['type'])) {
	header("Location: admin/");
}
elseif (!empty($_SESSION['laboratory'])&&!empty($_SESSION['type'])) {
	header("Location: laboratory/");
}
elseif (!empty($_SESSION['doctor'])&&!empty($_SESSION['type'])) {
	header("Location: doctor/");
}
elseif (!empty($_SESSION['reception'])&&!empty($_SESSION['type'])) {
	header("Location: reception/");
}
elseif (!empty($_SESSION['bursar'])&&!empty($_SESSION['type'])) {
	header("Location: reception/");
}
?>

<!DOCTYPE html>
<html>
<head>
	<title>Hospital Management System - Login</title>
			<html>
<head><title>Put Image in HTML</title>
</head>

<center>
<body background = "">

<img src = "hospital.jpg" width="1100px" height="300px"/>

</body></center>
</html>
	<style type="text/css">
	body
	{

		background-color: #;
	}
		.wrapper
		{
			height: 250px;
			width: 750px;
			background-color: white;
			border: 10px solid #1E90FF;
			margin: 0 auto;
			margin-top: 0px;
		}
		.left
		{
			height: 170px;
			width: 350px;
			border-right: 10px solid #1E90FF;
			float: left;
			font-family: Arial;
			font-size: 25px;
			text-align: center;
			padding-top: 80px;
		}
		.right
		{
			height: 250px;
			width: 390px;
			float: left;
			text-align: center;
			font-family: Arial;
		}
		hr
		{
			border-bottom: 10px solid #1E90FF;
			border-top: 1px solid white;
		}
		.input
		{

			height: 30px;
			width: 50%;
			padding-left: 20px;
		}
		.btn
		{
			height: 35px;
			width: 80%;
			border: 0;
			background-color:#1E90FF;
			margin: 0;
			color: white;
			font-weight: bold;
			cursor: pointer;
		}
	</style>
</head>
<body>
<div class="wrapper">
	<div class="left">
		Hospital Management System<br><br>(H:M:S)
	</div>
	<div class="right">
		<h3>Login Here</h3><hr>
		<form action="index.php" method="post">
			<input type="text" class="input" name="username" placeholder="Enter Username"><br><br>
			<input type="password" class="input" name="password" placeholder="Enter Password"><br><br>
			<input type="submit" class="btn" name="btn" value="Login"><br>
		</form>
<?php
		extract($_POST);
		if (isset($btn) && !empty($username) && !empty($password)) {
			require 'includes/users.php';
		 	login();
		 } 
		 ?>
	</div>
</div>
</body>
</html>
