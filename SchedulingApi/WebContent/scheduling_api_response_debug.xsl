<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html>
			<head>
				<title>Scheduling Tool - Test</title>
				<meta name="ROBOTS" content="NOINDEX, NOFOLLOW" />
				<link rel="stylesheet" type="text/css" href="./scheduling_api_response.css" />
			</head>
			<body>
				<div id="header">
					<form id="search" method="get">
						<input type="text" class="input" name="name" size="21" maxlength="120" />
						<input type="submit" value="search" class="button" />
					</form>
					<div class="clear"></div>
				</div>
				<xsl:variable name="error" select="ApiResponse/Error" />
				<xsl:choose>
					<xsl:when test="$error != ''">
						<div id="error">
							<p class="error"><xsl:value-of select="ApiResponse/Error"/></p>
						</div>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="searchResult" select="ApiResponse/SearchResult" />
						<xsl:choose>
							<xsl:when test="$searchResult != ''">
								<div id="searchResult">
									<h3>Search result</h3>
									<table class="search">
										<tr class="search">
											<th class="search">Client Site</th>
											<th class="search">Site Certification</th>
											<th class="search">Work Item</th>
											<th class="search">Status</th>
											<th class="search">Start/Target Date</th>
										</tr>
									<xsl:for-each select="ApiResponse/SearchResult">
										<tr class="search">
											<xsl:variable name="wiName" select="concat('?name=',name)"/>
											<td class="search"><xsl:value-of select="clientSite/name"/></td>
											<td class="search"><xsl:value-of select="siteCertName"/></td>
											<td class="search"><a href="{$wiName}"><xsl:value-of select="name" /></a></td>
											<td class="search"><xsl:value-of select="sfStatus"/></td>
											<td class="search"><xsl:value-of select="concat(
														substring(startDate, 9, 2),
														'/',
														substring(startDate, 6, 2),
														'/',
														substring(startDate, 1, 4)
														)"/></td>
										</tr>
									</xsl:for-each>
									</table>
								</div>
							</xsl:when>
							<xsl:otherwise>
								<div id="response">
									<div id="client">
									<h1><xsl:value-of select="ApiResponse/Client/name"/></h1>
										<div id = "client_details">
											<table class="details">
												<tr><td><xsl:value-of select="ApiResponse/Client/ClientSite/Location/address_1"/></td></tr>
												<tr><td><xsl:value-of select="ApiResponse/Client/ClientSite/Location/city"/></td></tr>
												<tr><td><xsl:value-of select="ApiResponse/Client/ClientSite/Location/state"/>&#160;&#160;<xsl:value-of select="ApiResponse/Client/ClientSite/Location/postCode"/></td></tr>
												<tr><td><xsl:value-of select="ApiResponse/Client/ClientSite/Location/country"/></td></tr>
											</table>
										</div>
									</div>
									<div id="site_cert">
										<h2>Site Certification: <xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/name"/></h2>
									</div>
									<div id="work_item">
										<h3>Work Item: <xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/name"/></h3>
										<div id="work_item_details">
											<table class="details">
												<tr>
													<td class="details">Revenue Ownership</td>
													<td class="details_data"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/revenueOwnershipName"/></td>
												</tr>
												<tr>
													<td class="details">Type</td>
													<td class="details_data"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/type"/></td>
												</tr>
												<tr>
													<td class="details">Status</td>
													<xsl:variable name="status" select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/sfStatus" />
													<xsl:choose>
														<xsl:when test="$status = 'Cancelled'">
															<td class="details_data_highlight"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/sfStatus"/></td>
														</xsl:when>
														<xsl:otherwise>
															<td class="details_data"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/sfStatus"/></td>
														</xsl:otherwise>
													</xsl:choose>
												</tr>
												<tr>
													<td class="details">Open Sub Status</td>
													<td class="details_data"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/openStatusSubType"/></td>
												</tr>
												<tr>
													<td class="details">Required Duration</td>
													<td class="details_data"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/requiredDuration"/></td>
												</tr>
												<tr>
													<td class="details">Start Date</td>
													<td class="details_data"><xsl:value-of select="concat(
														substring(ApiResponse/Client/ClientSite/SiteCertification/WorkItem/startDate, 9, 2),
														'/',
														substring(ApiResponse/Client/ClientSite/SiteCertification/WorkItem/startDate, 6, 2),
														'/',
														substring(ApiResponse/Client/ClientSite/SiteCertification/WorkItem/startDate, 1, 4)
														)"/></td>
												</tr>
												<tr>
													<td class="details">Target Date</td>
													<td class="details_data"><xsl:value-of select="concat(
														substring(ApiResponse/Client/ClientSite/SiteCertification/WorkItem/targetDate, 9, 2),
														'/',
														substring(ApiResponse/Client/ClientSite/SiteCertification/WorkItem/targetDate, 6, 2),
														'/',
														substring(ApiResponse/Client/ClientSite/SiteCertification/WorkItem/targetDate, 1, 4)
														)"/></td>
												</tr>
												<tr>
													<td class="details">Comments</td>
													<td class="details_data"><xsl:value-of select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/comment"/></td>
												</tr>
											</table>
										</div>
										<div id="work_item_requirements">
											<h4>Requirements</h4>
											<table class="details">
												<xsl:for-each select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/requiredCompetencies">
													<tr>
													  <xsl:variable name="competencyType" select="type" />
													  <xsl:choose>
														<xsl:when test="$competencyType = 'PRIMARYSTANDARD'">
															<td class="details">Primary Standard:</td>
														</xsl:when>
														<xsl:when test="$competencyType = 'STANDARD'">
															<td class="details">Standard:</td>
														</xsl:when>
														<xsl:otherwise>
															<td class="details">Code:</td>
														</xsl:otherwise>
													  </xsl:choose>
													  <td><xsl:value-of select="competencyName"/></td>
													</tr>
												</xsl:for-each>
												<xsl:for-each select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/preferredResourceNames">
													<xsl:if test=". != ''">
														<tr>
														  <td class="details">Preferred Resource:</td>
														  <td><xsl:value-of select="."/></td>
														</tr>
													</xsl:if>
												</xsl:for-each>
											</table>
										</div>
										<xsl:variable name="wistatus" select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/sfStatus" />
										<xsl:choose>
											<xsl:when test="$wistatus != 'Cancelled'">
												<div id="work_item_resources">
													<h4>Resources</h4>
													<table class="resources">
														<tr>
															<th class="resources" style="text-align:left;">Name</th>
															<th class="resources">Type</th>
															<th class="resources">Business Unit</th>
															<th class="resources">Office Distance (km)</th>
															<th class="resources">Home Distance (km)</th>
															<th class="resources">Travel Type</th>
															<th class="resources">Utilisation</th>
															<th class="resources">Travel Time</th>
															<th class="resources">Travel Cost</th>
															<th class="resources">Resource Cost</th>
															<th class="resources">Score</th>
															<xsl:choose>
																<xsl:when test="$wistatus = 'Open'">
																	<th class="resources">Available Days</th>
																</xsl:when>
																<xsl:when test="$wistatus = 'Scheduled'">
																	<th class="resources">Available Days</th>
																</xsl:when>
																<xsl:otherwise>
																	<th class="resources">Audit Days</th>
																</xsl:otherwise>
															</xsl:choose>
														</tr>
														
														<xsl:for-each select="ApiResponse/Client/ClientSite/SiteCertification/WorkItem/Resource">
															<xsl:variable name="pointer" select="position()" />
															<xsl:choose>
																<xsl:when test="$pointer = 1">
																	<tr>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th></th>
																		<th>
																			<table class="days">
																				<tr>
																					<xsl:for-each select="availablePeriods/period">
																						<th class="days"><xsl:value-of select="name"/></th>
																					</xsl:for-each>
																				</tr>
																			</table>
																		</th>													
																	</tr>
																</xsl:when>
															</xsl:choose>
															
															<tr class="resources">
															  <td class="resources" style="text-align:left;"><xsl:value-of select="name"/></td>
															  <td class="resources"><xsl:value-of select="type"/></td>
															  <td class="resources"><xsl:value-of select="reportingBusinessUnit"/></td>
															  <td class="resources"><xsl:value-of select="format-number(distanceFromClient, '#.##')"/></td>
															  <td class="resources"><xsl:value-of select="format-number(homeDistanceFromClient, '#.##')"/></td>
															  <xsl:variable name="travelType" select="travelType" />
															  <xsl:choose>
																<xsl:when test="$travelType = 'FLY'">
																	<td class="resources"><img src="./fly.gif" alt="Fly" /></td>
																</xsl:when>
																<xsl:when test="$travelType = 'DRIVE'">
																	<xsl:variable name="gMapsUrl" select="concat(
																		'https://maps.google.com/maps?saddr=', 
																		home/address_1, ' ',
																		home/address_2, ' ',
																		home/address_3, ' ',
																		home/city, ' ',
																		home/state, ' ',
																		home/country, ' ',
																		home/postCode, ' ', 
																		'&amp;daddr=' ,
																		/ApiResponse/Client/ClientSite/Location/address_1, ' ',
																		/ApiResponse/Client/ClientSite/Location/address_2, ' ',
																		/ApiResponse/Client/ClientSite/Location/address_3, ' ',
																		/ApiResponse/Client/ClientSite/Location/city, ' ',
																		/ApiResponse/Client/ClientSite/Location/state, ' ',
																		/ApiResponse/Client/ClientSite/Location/country, ' ',
																		/ApiResponse/Client/ClientSite/Location/postCode, ' '
																	)"/>
																	<td class="resources"><a href="{$gMapsUrl}" title="click for Google Maps directions" target="_blank"><img src="./drive.gif" alt="Drive"  />&#160;Map</a></td>
																</xsl:when>
																<xsl:otherwise>
																	<td class="resources">?</td>
																</xsl:otherwise>
															  </xsl:choose>
															  <td class="resources"><xsl:value-of select="format-number(utilization, '#.##%')"/></td>
															  <td class="resources"><xsl:value-of select="format-number(travelTime, '#.##')"/></td>
															  <td class="resources"><xsl:value-of select="format-number(travelCost, '#.##')"/></td>
															  <td class="resources"><xsl:value-of select="format-number(resourceCost, '#.##')"/></td>
															  <td class="resources"><xsl:value-of select="format-number(score, '#.##')"/></td>
															  <td class="resources">
																  <table class="days">
																	<tr  class="days">							
																		<xsl:for-each select="availablePeriods/period">
																			<td class="days">
																				<xsl:for-each select="day">
																					<xsl:value-of select="."/>&#160;
																				</xsl:for-each>
																			</td>
																		</xsl:for-each>
																	</tr>
																</table>
															  </td>
															</tr>
														</xsl:for-each>
													</table>
												</div>
											</xsl:when>
										</xsl:choose>
									</div>
								</div>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>			
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>