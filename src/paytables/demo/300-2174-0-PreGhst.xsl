<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var allGrids = scenario.split('|');
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');

						// find wins
						const lines = [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]];
						const prizes = '8'; // 'ABCDEFGHIJKLM';
						var doBonusGrids = (allGrids[0].indexOf('W') != -1);
						var tempLine = '';
						var prizeLine = '';
						var prizeRegex = '';
						var regexStr = '';
						var winLine = 0;
						var winPrize = '';
						var r = [];
						var gridPos = 0;
						var gridTitle = '';
						var winPrizes = '';
						var grid = '';
						var gridPrize = '';
						var gridMultiplier = '';

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

						for (var gridIndex=0; gridIndex<allGrids.length; gridIndex++)
						{
							winPrizes = '';

							if (gridIndex == 0 || doBonusGrids)
							{ 
								for (var line=0; line<lines.length; line++)
								{
									gridPrize = allGrids[gridIndex].split(",")[0];
									gridMultiplier = allGrids[gridIndex].split(",")[1];
									grid = allGrids[gridIndex].split(",")[2];
									tempLine = '';

									for (var cell=0; cell<3; cell++)
									{
										// tempLine += allGrids[gridIndex][lines[line][cell]];
										tempLine += grid[lines[line][cell]];
									}

									for (var prize=0; prize<prizes.length; prize++)
									{
										regexStr = '[^W' + prizes[prize] + ']';
										prizeRegex = new RegExp(regexStr,'g');
										prizeLine = tempLine.replace(prizeRegex, '');

										if (prizeLine.length == 3)
										{
											winPrizes += line.toString() + gridPrize; //prizes[prize];
										}
									}
								}
							}

							// Output grid table.

							gridPos = 0;
							gridTitle = (gridIndex == 0) ? getTranslationByName("gridStandard", translations) :
											 (gridIndex == 1) ? ((doBonusGrids) ? getTranslationByName("gridBonus", translations) : '')
															 : '';

							if (gridTitle != '')
							{
								r.push('<tr>');	
								r.push('<td class="tablehead" colspan="3">' + gridTitle + '</td>');
								r.push('<td class="tablebody">&nbsp;</td>');
								r.push('<td class="tablehead" colspan="11">' + ((gridIndex == 0 || doBonusGrids) ? getTranslationByName("prizes", translations) : '') + '</td>');
								r.push('</tr>');							
							
								r.push('<tr>');
								r.push('<td class="tablebody">&nbsp;</td>');
								r.push('</tr>');
							}

							if (gridIndex == 0 || doBonusGrids)
							{
								gridMultiplier = allGrids[gridIndex].split(",")[1];
								grid = allGrids[gridIndex].split(",")[2];
								for (var gridRow=0; gridRow<3; gridRow++)
								{
									r.push('<tr>');

									for (var gridCol=0; gridCol<3; gridCol++)
									{
										gridPos = gridRow * 3 + gridCol;

										if (grid[gridPos] == "W") 
										{
											r.push('<td class="tablebody" style="text-align:center" width="50px">' + getTranslationByName(grid[gridPos], translations) + '</td>');								
										}
										else
										{
											r.push('<td class="tablebody" style="text-align:center" width="50px">' + grid[gridPos] + '</td>');								
										}
									}

									for (var gridWins=0; gridWins<(winPrizes.length / 2); gridWins++)
									{
										r.push('<td class="tablebody">&nbsp;</td>');

										winLine = parseInt(winPrizes[gridWins * 2]);

										for (var gridCol=0; gridCol<3; gridCol++)
										{
											gridPos = gridRow * 3 + gridCol;

											if (lines[winLine].indexOf(gridPos) != -1)
											{
												if (grid[gridPos] == "W") 
												{
													r.push('<td class="tablebody" style="text-align:center" width="50px">' + getTranslationByName(grid[gridPos], translations) + '</td>');
												}
												else
												{
													r.push('<td class="tablebody" style="text-align:center" width="50px">' + grid[gridPos] + '</td>');
												}
											}
											else
											{
												r.push('<td class="tablebody" style="text-align:center" width="50px">.</td>');
											}
										}
									}

									r.push('</tr>');
								}

								r.push('<tr>');
								r.push('<td class="tablebody" colspan="3">&nbsp;</td>');

								for (var gridWins=0; gridWins<(winPrizes.length / 2); gridWins++)
								{
									r.push('<td class="tablebody">&nbsp;</td>');

									winPrize = winPrizes[gridWins * 2 + 1];

									r.push('<td class="tablebody" colspan="3">' + convertedPrizeValues[getPrizeNameIndex(prizeNames,winPrize)] + ' x ' + gridMultiplier + '</td>');
								}

								r.push('</tr>');
							}

							if (winPrizes != '')
							{
								r.push('<tr>');
								r.push('<td class="tablebody">&nbsp;</td>');
								r.push('</tr>');
							}
						}

						r.push('</table>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
						r.push('</table>');
							
						}
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");


						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">

					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
				<x:text>|</x:text>
				<x:call-template name="Utils.ApplyConversionByLocale">
					<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
					<x:with-param name="code" select="/output/denom/currencycode" />
					<x:with-param name="locale" select="//translation/@language" />
				</x:call-template>
			</x:template>
			
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>