#!/usr/bin/perl
# (c) 2013 uski
# Distribution, copying, modifications are prohibited without permission from the original creator.
# Commercial distribution requires a license.

print "<style>\n";
print "table.asic,tr,td,th { border: 1px black solid; border-collapse: collapse; }\n";
print "span.green { color: #22cc00; }\n";
print "span.red { color: #cc2200; }\n";
print "</style>\n";

print "<p>Did BertMod help you ? Please help back !<br/>Donations are welcome to 1oHj13eEj1cctkUHzwWq38niBSX13WsSt<br/>Thank you. -- uski</p>\n";

my $cg_stats = `echo "summary|" | nc 127.0.0.1 4028 2>&1`;

if ($cg_stats =~ /Connection refused/)
{
	print "<p><span class=\"red\">Warning: Could not reach cgminer/bfgminer !</span>\n";
	print "<br/>Make sure API access is enabled at least from 127.0.0.1</p>\n";
}
else
{
	$cg_stats =~ s/,/\r\n/g;
	print "<pre>$cg_stats</pre>\n";
}

print "<table style=\"border: 1px black solid; border-collapse: collapse;\">\n";

print "<tr>\n";
print "<th>ASIC Board</th>\n";
print "<th>Info</th>\n";
print "</tr>\n";

my $dcdc_wout_total = 0;

for (my $i=0; $i <= 5; $i++) {
	my $bus = $i + 3;

	# Read the temperature.
	my $rawtemp=`/usr/sbin/i2cget -y $bus 0x48 0 w`;
	# If we have a temperature, the board is here.
	# We'll display temperature and some other info.
	if ($rawtemp)
	{
		print "<tr>\n";
		print "<th>$i</th>\n";

		print "<td>\n";

		$rawtemp =~ s/0x([0-9a-fA-F]{4}).*/\1/;
		my @temp=unpack("cC", pack("H*", $rawtemp));
		my $curspan="green";

		if ($temp[1] > 65)
		{
			$curspan="red";
		}

		if ($temp[0] & 128)
		{
			print "<p>Temperature sensor: <span class=\"".$curspan."\">".$temp[1].".5 C</span></p>\n";
		}
		else
		{
			print "<p>Temperature sensor: <span class=\"".$curspan."\">".$temp[1].".0 C</span></p>\n";
		}

		print "<table style=\"border: 1px black solid; border-collapse: collapse;\">\n";
		print "<tr>\n";
		print "<th>Die ID</th>\n";
		print "<th>Cores ON</th>\n";
		print "<th>Cores OFF</th>\n";
		print "<th>%</th>\n";
		print "</tr>\n";
		for (my $subdie=0; $subdie <= 3; $subdie++) {
			my $dies_off = 0;
			my $dies_on = 0;

			for (my $diecore=0; $diecore < 48; $diecore++) {
				my $dieid = $subdie * 48 + $diecore;
				my $core_status = `/usr/sbin/i2cget -y 2 0x2$i $dieid`;
				$core_status = hex $core_status;
				if ($core_status == 3)
				{
					$dies_on = $dies_on + 1;
				}
				else
				{
					$dies_off = $dies_off + 1;
				}
			}
			print "<tr>\n";
			print "<td>".$subdie."</td><td>".$dies_on."</td><td>".$dies_off."</td>\n";
			my $percent_dies_on = ($dies_on / 48)*100;
			$percent_dies_on = sprintf("%0.3g", $percent_dies_on);
			print "<td>".$percent_dies_on."</td>";
			print "</tr>\n";
		}
		print "</table>\n";


		print "<table style=\"border: 1px black solid; border-collapse: collapse;\">\n";
		print "<tr>\n";
		print "<th>DC/DC ID</th>\n";
		print "<th>ON/OFF</th>\n";
		print "<th>Status</th>\n";
		print "<th>Input Voltage</th>\n";
		print "<th>Output Voltage</th>\n";
		print "<th>Output Current</th>\n";
		print "</tr>\n";
		for (my $dcdc=0; $dcdc <= 7; $dcdc++) {
			print "<tr>\n";
			print "<th>$dcdc</th>\n";

			my $dcdc_onoff = `/usr/sbin/i2cget -y $bus 0x1$dcdc 2`;
			if ($dcdc_onoff eq "")
			{
				print "<td colspan=5>No DC/DC detected (this is not an error)</td></tr>\n";
			        next;
			}
			$dcdc_onoff =~ s/\R//g; # strip CRLF
			$dcdc_onoff = hex $dcdc_onoff; # parse hex
			if ($dcdc_onoff == 23) # from monitordcdc
			{
				print "<td><span class=\"green\">ON</span></td>\n";
			}
			else
			{
				print "<td>OFF</td>\n";
			}

			# GET STATUS BYTE

			my $dcdc_status = `/usr/sbin/i2cget -y $bus 0x1$dcdc 0x78`;
			$dcdc_status =~ s/\R//g;
			$dcdc_status = hex $dcdc_status;
			if (($dcdc_status & 61) > 0) # ignore comm fault
			{
				print "<td><span class=\"red\">FAULT $dcdc_status</span></td>\n";
			}
			elsif (($dcdc_status & 64) > 0)
			{
				print "<td>OFF</td>\n";
			}
			else
			{
				print "<td><span class=\"green\">OK</span></td>\n";
			}

			# GET VOUT MODE (exponent)


			my $dcdc_voutmode_exp = 9999;
			my $dcdc_voutmode_raw = `/usr/sbin/i2cget -y $bus 0x1$dcdc 0x20`;
			$dcdc_voutmode_raw =~ s/\R//g;
			$dcdc_voutmode_raw = (hex $dcdc_voutmode_raw);
			if (($dcdc_voutmode_raw & 224) != 0)
			{
				$dcdc_voutmode_raw = 9999;
				# We only support "linear" mode
				# So if it's another mode, set this special value
				# which will hide VOUT (see code below)
			}
			else
			{
				$dcdc_voutmode_exp = $dcdc_voutmode_raw & 31;
				if ($dcdc_voutmode_exp >= 16)
				{
					$dcdc_voutmode_exp = -32+$dcdc_voutmode_exp;
				}
			}

			# GET INPUT VOLTAGE

			my $dcdc_vin_raw = `/usr/sbin/i2cget -y $bus 0x1$dcdc 0x88 w`;
			$dcdc_vin_raw =~ s/\R//g;
			$dcdc_vin_raw = hex $dcdc_vin_raw;
			my $dcdc_vin_exp = ($dcdc_vin_raw & 63488) >> 11;
			my $dcdc_vin_man = $dcdc_vin_raw & 2047;
			if ($dcdc_vin_exp >= 16)
			{
				$dcdc_vin_exp = -32+$dcdc_vin_exp;
			}
			my $dcdc_vin = $dcdc_vin_man * (2**$dcdc_vin_exp);
			$dcdc_vin = sprintf("%0.3g", $dcdc_vin);
			print "<td>$dcdc_vin V</td>\n";

			# GET OUTPUT VOLTAGE

			my $dcdc_vout_raw = `/usr/sbin/i2cget -y $bus 0x1$dcdc 0x8B w`;
			$dcdc_vout_raw =~ s/\R//g;
			my $dcdc_vout=(hex $dcdc_vout_raw) * (2**$dcdc_voutmode_exp);
			$dcdc_vout = sprintf("%0.3g", $dcdc_vout);

			if ($dcdc_voutmode_exp != 9999)
			{
				print "<td>$dcdc_vout V</td>\n";
			}
			else
			{
				print "<td>(encoding not supported)</td>\n";
				$dcdc_vout = 0; # Prevent funky power values
			}

			# GET OUTPUT CURRENT

			my $dcdc_iout_raw = `/usr/sbin/i2cget -y $bus 0x1$dcdc 0x8C w`;
			$dcdc_iout_raw =~ s/\R//g;
			$dcdc_iout_raw = hex $dcdc_iout_raw;
			my $dcdc_iout_exp = ($dcdc_iout_raw & 63488) >> 11;
			my $dcdc_iout_man = $dcdc_iout_raw & 2047;
			if ($dcdc_iout_exp >= 16)
			{
				$dcdc_iout_exp = -32+$dcdc_iout_exp;
			}
			my $dcdc_iout = ($dcdc_iout_man * (2**$dcdc_iout_exp));
			$dcdc_iout = sprintf("%0.3g", $dcdc_iout);
			print "<td>$dcdc_iout A";
			if ($dcdc_iout > 1)
			{
				$dcdc_wout = $dcdc_iout * $dcdc_vout;
				$dcdc_wout = sprintf("%0.3g", $dcdc_wout);
				print " (".$dcdc_wout." W)";
				$dcdc_wout_total = $dcdc_wout_total + $dcdc_wout;
			}
			print "</td>\n";

			print "</tr>\n";
		}

		print "</table>\n";
		print "</td>\n";
		print "</tr>\n";

	}
}

print "</table>\n";

$dcdc_wout_total = sprintf("%d", $dcdc_wout_total);
print "<p>Total DC/DC power output: ".$dcdc_wout_total." W</p>";
