<?php 

function patients()
{
		require 'connect.php';
			//$typee = $_SESSION['type'];
			$sql = "SELECT * FROM hospital.medication WHERE  `status`='pharmacy'";
	$query = mysqli_query($con,$sql);
	while ($row = mysqli_fetch_array($query)) {
		$ido = $row['patient_id'];
		$sql2 = "SELECT * FROM hospital.patient WHERE `id`='$ido'";
		$query2 = mysqli_query($con,$sql2);
		while ($row2 = mysqli_fetch_array($query2)) {
			echo "<tr height=30px'>";
			echo "<td>P-".$row2['id']."</td>";
			echo "<td>".$row2['fname']."</td>";
			echo "<td>".$row2['sname']."</td>";
			echo "<td>".$row2['sex']."</td>";
			echo "<td><center><a href='medicine.php?id=".$row['id']."'>view</a></center></td>";
			echo "</tr>";
		}
		
	}
}

function addmedicine()
{
		require 'connect.php';
			$price = trim(htmlspecialchars($_POST['price']));
			if (!empty($price)) {
				$id = $_GET['id'];
				@require_once "connect.php";

				$sql = "UPDATE hospital.medication SET `status`='finish',`medical_price`='$price'  WHERE `id`='$id'";
				$query = mysqli_query($con,$sql);
				if (!empty($query)) {
					echo "<br><b style='color:#008080;font-size:14px;font-family:Arial;'>Finished!</b><br><br>";
				}
			}
}

function addmedicines()
{
		require 'connect.php';
			$name = trim(htmlspecialchars($_POST['name']));
			$price = trim(htmlspecialchars($_POST['price']));
			if (!empty($name)&&!empty($price)) {
				@require_once "connect.php";

				//$sql = "UPDATE hospital.medication` SET `status`='finish',`medical_price`='$price'  WHERE `id`='$id'";
				$sql = "INSERT INTO hospital.medicine VALUES ('','$name','$price')";
				$query = mysqli_query($con,$sql);
				if (!empty($query)) {
					echo "<br><b style='color:#008080;font-size:14px;font-family:Arial;'>Medicine Added</b><br><br>";
				}
			}
}

function updatemedicines()
{
		require 'connect.php';
			$name = trim(htmlspecialchars($_POST['name']));
			$price = trim(htmlspecialchars($_POST['price']));
			if (!empty($name)&&!empty($price)) {
				@require_once "connect.php";

				$id = $_GET['id'];

				$sql = "UPDATE hospital.medicine SET `medicine_name`='$name',`price`='$price'  WHERE `id`='$id'";
				//$sql = "INSERT INTO hospital.medicine` VALUES ('','$name','$price')";
				$query = mysqli_query($con,$sql);
				if (!empty($query)) {
					echo "<br><b style='color:#008080;font-size:14px;font-family:Arial;'>Medicine Updated</b><br><br>";
				}
			}
}

function searchmedicine()
{
			require 'connect.php';
			$name = $_GET['s'];
				$sql2 = "SELECT * FROM hospital.medicine WHERE `medicine_name` LIKE '%$name%'";
				$query2 = mysqli_query($con,$sql2);
		while ($row2 = mysqli_fetch_array($query2)) {
			echo "<tr height=30px'>";
		echo "<td>".$row2['medicine_name']."</td>";
		echo "<td>".$row2['price']."</td>";
		echo "<td><center><a href='editmedicine.php?id=".$row2['id']."'><img src='../assets/img/glyphicons-151-edit.png' height='16px' width='17px'></a></center></td>";
		echo "<td><center><a href='deletemedicine.php?id=".$row2['id']."'><img src='../assets/img/glyphicons-17-bin.png' height='16px' width='12px'></a></center></td>";
	
		echo "</tr>";
		}
}

function searchpatients()
{
		require 'connect.php';
	$name = $_GET['s'];
	$sql = "SELECT * FROM hospital.medication WHERE  `status`='pharmacy'";
	$query = mysqli_query($con,$sql);
	while ($row = mysqli_fetch_array($query)) {
		$ido = $row['patient_id'];
		$sql2 = "SELECT * FROM hospital.patient WHERE `id`='$ido' AND `id` LIKE '%$name%'";
		$query2 = mysqli_query($con,$sql2);
		while ($row2 = mysqli_fetch_array($query2)) {
			echo "<tr height=30px'>";
			echo "<td>P-".$row2['id']."</td>";
			echo "<td>".$row2['fname']."</td>";
			echo "<td>".$row2['sname']."</td>";
			echo "<td>".$row2['sex']."</td>";
			echo "<td><center><a href='medicine.php?id=".$row['id']."'>view</a></center></td>";
			echo "</tr>";
		}
		
	}
}

function medicine()
{
	@require 'connect.php';
	$sql = "SELECT * FROM hospital.medicine";
	$query = mysqli_query($con,$sql);
	while ($row = mysqli_fetch_array($query)) {
		echo "<tr height=30px'>";
		echo "<td>".$row['medicine_name']."</td>";
		echo "<td>".$row['price']."</td>";
		echo "<td><center><a href='editmedicine.php?id=".$row['id']."'><img src='../assets/img/glyphicons-151-edit.png' height='16px' width='17px'></a></center></td>";
		echo "<td><center><a href='deletemedicine.php?id=".$row['id']."'><img src='../assets/img/glyphicons-17-bin.png' height='16px' width='12px'></a></center></td>";
	
		echo "</tr>";
	}
}

function settings()
{
		require 'connect.php';
	//$username = trim(htmlspecialchars($_POST['username']));
	$fname = trim(htmlspecialchars($_POST['fname']));
	$sname = trim(htmlspecialchars($_POST['sname']));
	$password2 = trim(htmlspecialchars($_POST['password2']));
	$password = trim(htmlspecialchars($_POST['password']));
	if ($password != $password) {
		echo "<br><b style='color:red;font-size:14px;font-family:Arial;'>Password Must Match</b>";
	}
	else{
		$pass = sha1($password);
		$name = $_SESSION['pharmacy'];
		$type = $_SESSION['type'];
			
				$sql = "UPDATE hospital.users SET `fname`='$fname',`sname`='$sname',`password`='$pass' WHERE `username`='$name' AND `type`='$type'";
				$query = mysqli_query($con,$sql);
				if (!empty($query)) {
					echo "<br><b style='color:#008080;font-size:14px;font-family:Arial;'>Succesifully Updated</b>";

				}	
		}
	}
?>