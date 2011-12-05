<!---
*
* Copyright (C) 2005-2008 Razuna
*
* This file is part of Razuna - Enterprise Digital Asset Management.
*
* Razuna is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Razuna is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero Public License for more details.
*
* You should have received a copy of the GNU Affero Public License
* along with Razuna. If not, see <http://www.gnu.org/licenses/>.
*
* You may restribute this Program with a special exception to the terms
* and conditions of version 3.0 of the AGPL as described in Razuna's
* FLOSS exception. You should have received a copy of the FLOSS exception
* along with Razuna. If not, see <http://www.razuna.com/licenses/>.
*
--->
<cfcomponent output="false" extends="extQueryCaching">

	<!--- Rendering Farm: Get all --->
	<cffunction name="rfs_get_all" output="true">
		<cfargument name="thestruct" type="struct">
		<!--- Query --->
		<cfquery dataSource="#application.razuna.datasource#" name="qry">
		SELECT rfs_id, rfs_server_name, rfs_active
		FROM rfs
		ORDER BY rfs_date_change
		</cfquery>
		<!--- Return --->
		<cfreturn qry>
	</cffunction>
	
	<!--- Rendering Farm: get detail --->
	<cffunction name="rfs_get_detail" output="true">
		<cfargument name="rfs_id" type="string" required="true">
		<!--- Query --->
		<cfquery dataSource="#application.razuna.datasource#" name="qry">
		SELECT rfs_id, rfs_active, rfs_server_name, rfs_imagemagick, rfs_ffmpeg, rfs_dcraw, rfs_exiftool, rfs_wget, rfs_date_add, rfs_date_change
		FROM rfs
		WHERE rfs_id = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.rfs_id#">
		</cfquery>
		<!--- Return --->
		<cfreturn qry>
	</cffunction>
	
	<!--- Rendering Farm: update --->
	<cffunction name="rfs_update" output="true">
		<cfargument name="thestruct" type="struct" required="true">
		<!--- If we add a record then do an insert --->
		<cfif arguments.thestruct.rfs_add>
			<!--- Insert --->
			<cfquery dataSource="#application.razuna.datasource#" name="qry">
			INSERT INTO rfs
			(
			rfs_id,
			rfs_active,
			rfs_server_name,
			rfs_imagemagick,
			rfs_ffmpeg,
			rfs_dcraw,
			rfs_exiftool,
			rfs_wget,
			rfs_date_add,
			rfs_date_change
			)
			VALUES
			(
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_id#">,
			<cfqueryparam CFSQLType="CF_SQL_DOUBLE" value="#arguments.thestruct.rfs_active#">,
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_server_name#">,
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_imagemagick#">,
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_ffmpeg#">,
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_dcraw#">,
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_exiftool#">,
			<cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_wget#">,
			<cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#now()#">,
			<cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#now()#">
			)
			</cfquery>
		<cfelse>
			<!--- Update --->
			<cfquery dataSource="#application.razuna.datasource#" name="qry">
			UPDATE rfs
			SET
			rfs_active = <cfqueryparam CFSQLType="CF_SQL_DOUBLE" value="#arguments.thestruct.rfs_active#">,
			rfs_server_name = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_server_name#">,
			rfs_imagemagick = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_imagemagick#">,
			rfs_ffmpeg = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_ffmpeg#">,
			rfs_dcraw = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_dcraw#">,
			rfs_exiftool = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_exiftool#">,
			rfs_wget = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_wget#">,
			rfs_date_change = <cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#now()#">
			WHERE rfs_id = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_id#">
			</cfquery>
		</cfif>
		<!--- Return --->
		<cfreturn />
	</cffunction>
	
	<!--- Notify remote server --->
	<cffunction name="notify" output="true">
		<cfargument name="thestruct" type="struct">
		<!--- Param --->
		<cfparam name="arguments.thestruct.upl_template" default="0" />
		<!--- Get remote server records --->
		<cfquery dataSource="#application.razuna.datasource#" name="qry">
		SELECT rfs_id, rfs_server_name
		FROM rfs
		WHERE rfs_active = <cfqueryparam CFSQLType="CF_SQL_DOUBLE" value="true">
		</cfquery>
		<!--- Check here is the server is busy or not. If so, check for an alternate server in the pool --->
		
		<!--- If this is from convert we write data into json --->
		<cfif structkeyexists(arguments.thestruct,"convert")>
			<!--- Variable --->
			<cfset var jdata = structnew()>
			<!--- Loop over structs --->
			<cfloop collection="#arguments.thestruct#" item="item">
				<!--- Only grab the needed fields --->
				<cfif item CONTAINS "file_id" OR item CONTAINS "convert">
					<!--- Add to struct --->
					<cfset structinsert(jdata, item, arguments.thestruct["#item#"])>
				</cfif>
			</cfloop>
			<!--- Create Json --->
			<cfset var jsondata = serializejson(jdata)>
		</cfif>
		<!--- Notify remote servers about a new file waiting for download --->
		<!--- Send the server ID with the request. The remote server checks the ID to this record --->
		<cfhttp url="#qry.rfs_server_name#" timeout="30">
			<cfhttpparam name="rfsid" value="#qry.rfs_id#" type="URL">
			<cfhttpparam name="hostid" value="#session.hostid#" type="URL">
			<cfhttpparam name="userid" value="#session.theuserid#" type="URL">
			<cfhttpparam name="dynpath" value="#arguments.thestruct.dynpath#" type="URL">
			<cfhttpparam name="httphost" value="#arguments.thestruct.httphost#" type="URL">
			<cfhttpparam name="storage" value="#application.razuna.storage#" type="URL">
			<cfhttpparam name="dsnhost" value="#application.razuna.datasource#" type="URL">
			<cfif structkeyexists(arguments.thestruct,"convert")>
				<cfhttpparam name="upl_template" value="#arguments.thestruct.upl_template#" type="URL">
				<cfhttpparam name="convert" value="#arguments.thestruct.convert#" type="URL">
				<cfhttpparam name="assettype" value="#arguments.thestruct.assettype#" type="URL">
				<cfhttpparam name="jsondata" value="#jsondata#" type="URL">
			<cfelse>
				<cfhttpparam name="tempid" value="#arguments.thestruct.tempid#" type="URL">
				<cfhttpparam name="assetid" value="#arguments.thestruct.newid#" type="URL">
			</cfif>
		</cfhttp>		
		<!--- Return --->
		<cfreturn />
	</cffunction>
	
	<cffunction name="SafeSerializeJSON" output="false" access="private" returntype="string">
		<cfargument name="obj" type="any" required="true" />
		<cfargument name="serializeQueryByColumns" type="boolean" required="false" default="false" />
		<cfset var jsonOutput = SerializeJSON(arguments.obj, arguments.serializeQueryByColumns) />
		<cfset jsonOutput = Replace(jsonOutput, chr(8232), "\u2028", "all") />
		<cfset jsonOutput = Replace(jsonOutput, chr(8233), "\u2029", "all") />
		<cfreturn jsonOutput />
	</cffunction>
	
	<!--- Pickup asset from rfs --->
	<cffunction name="pickup" output="true">
		<cfargument name="thestruct" type="struct">
		<cftry>
			<!--- Params --->
			<cfset var tt = replace(createuuid(),"-","","all")>
			<!--- Go grab the platform --->
			<cfinvoke component="assets" method="iswindows" returnvariable="iswindows">
			<!--- Prepare scripts --->
			<cfset arguments.thestruct.thesh = gettempdirectory() & "/#tt#.sh">
			<cfset arguments.thestruct.theshz = gettempdirectory() & "/#tt#z.sh">
			<cfif isWindows>
				<cfset arguments.thestruct.thesh = gettempdirectory() & "/#tt#.bat">
				<cfset arguments.thestruct.theshz = gettempdirectory() & "/#tt#z.bat">
			</cfif>
			<!--- IMAGES --->
			<cfif arguments.thestruct.rfs_assettype EQ "img">
				<cfset var forpath = "img">
			<!--- VIDEOS --->
			<cfelseif arguments.thestruct.rfs_assettype EQ "vid">
				<cfset var forpath = "vid">
			<!--- AUDIOS --->
			<cfelseif arguments.thestruct.rfs_assettype EQ "aud">
				<cfset var forpath = "aud">
			<!--- Docs and all other files --->
			<cfelse>
				<cfset var forpath = "doc">
			</cfif>
			<!--- If we come from convert we have jsondata in the arguments --->
			<cfif structkeyexists(arguments.thestruct,"rfs_jsondata")>
				<!--- Convert Json --->
				<cfset arguments.thestruct.json = deserializejson(arguments.thestruct.rfs_jsondata)>
				<cfset structappend(arguments.thestruct, arguments.thestruct.json)>
				<!--- Images --->
				<cfif forpath EQ "img">
					<cfquery dataSource="#application.razuna.datasource#" name="qry">
					SELECT folder_id_r
					FROM #session.hostdbprefix#images
					WHERE img_id = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.jsondata.file_id#">
					AND host_id = <cfqueryparam CFSQLType="CF_SQL_NUMERIC" value="#arguments.thestruct.hostid#">
					</cfquery>
				<!--- Videos --->
				<cfelseif forpath EQ "vid">
					<cfquery dataSource="#application.razuna.datasource#" name="qry">
					SELECT folder_id_r
					FROM #session.hostdbprefix#videos
					WHERE vid_id = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.jsondata.file_id#">
					AND host_id = <cfqueryparam CFSQLType="CF_SQL_NUMERIC" value="#arguments.thestruct.hostid#">
					</cfquery>
				<!--- Audios --->
				<cfelseif forpath EQ "aud">
					<cfquery dataSource="#application.razuna.datasource#" name="qry">
					SELECT folder_id_r
					FROM #session.hostdbprefix#audios
					WHERE aud_id = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.jsondata.file_id#">
					AND host_id = <cfqueryparam CFSQLType="CF_SQL_NUMERIC" value="#arguments.thestruct.hostid#">
					</cfquery>
				<!--- Docs and all other files --->
				<cfelse>
					<cfquery dataSource="#application.razuna.datasource#" name="qry">
					SELECT folder_id_r
					FROM #session.hostdbprefix#files
					WHERE file_id = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.jsondata.file_id#">
					AND host_id = <cfqueryparam CFSQLType="CF_SQL_NUMERIC" value="#arguments.thestruct.hostid#">
					</cfquery>
				</cfif>
				<!--- Put asset path together --->
				<cfset var storein = arguments.thestruct.assetpath & "/" & session.hostid & "/" & qry.folder_id_r & "/" & forpath & "/" & arguments.thestruct.newid>
				<!--- Write script file --->
				<cfif forpath EQ "aud">
					<cffile action="write" file="#arguments.thestruct.thesh#" output="wget -P #storein# #arguments.thestruct.rfs_server#/incoming/#arguments.thestruct.tempfolder#/#arguments.thestruct.newid#/#arguments.thestruct.convertname#" mode="777">
				<cfelse>
					<cffile action="write" file="#arguments.thestruct.thesh#" output="wget -P #storein# #arguments.thestruct.rfs_server#/incoming/#arguments.thestruct.tempfolder#/#arguments.thestruct.newid#/#arguments.thestruct.thumbname# #arguments.thestruct.rfs_server#/incoming/#arguments.thestruct.tempfolder#/#arguments.thestruct.newid#/#arguments.thestruct.convertname#" mode="777">
				</cfif>
			<!--- Pickup the preview asset --->
			<cfelse>
				<!--- Query temp DB --->
				<cfquery dataSource="#application.razuna.datasource#" name="qry">
				SELECT folder_id
				FROM #session.hostdbprefix#assets_temp
				WHERE tempid = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.thestruct.rfs_tempid#">
				</cfquery>		
				<!--- Put asset path together --->
				<cfset var storein = arguments.thestruct.assetpath & "/" & session.hostid & "/" & qry.folder_id & "/" & forpath & "/" & arguments.thestruct.rfs_assetid>
				<!--- Write script file --->
				<cffile action="write" file="#arguments.thestruct.thesh#" output="wget -P #storein# #arguments.thestruct.rfs_server#/incoming/#arguments.thestruct.rfs_path#/#arguments.thestruct.rfs_asset#" mode="777">
			</cfif>				
			<!--- Create folder --->
			<cfif NOT directoryexists(storein)>
				<cfdirectory action="create" directory="#storein#" mode="775">
			</cfif>						
			<!--- Get file --->
			<cfthread name="#tt#" intstruct="#arguments.thestruct#">
				<cfexecute name="#attributes.intstruct.thesh#" timeout="9000" />
			</cfthread>
			<!--- Wait for the thread above until the file is downloaded fully --->
			<cfthread action="join" name="#tt#" />
			<!--- Remove script --->
			<cffile action="delete" file="#arguments.thestruct.thesh#" />
			<!--- If we are DOC/PDF we need to download the PDf images folder (zip) and extract it --->
			<cfif forpath EQ "doc">
				<!--- Write script file --->
				<cffile action="write" file="#arguments.thestruct.theshz#" output="wget -P #storein# #arguments.thestruct.rfs_server#/incoming/#arguments.thestruct.rfs_path#/razuna_pdf_images.zip" mode="777">
				<!--- Get file --->
				<cfthread name="z#tt#" intstruct="#arguments.thestruct#">
					<cfexecute name="#attributes.intstruct.theshz#" timeout="9000" />
				</cfthread>
				<!--- Wait for the thread above until the file is downloaded fully --->
				<cfthread action="join" name="z#tt#" />
				<!--- Remove script --->
				<cffile action="delete" file="#arguments.thestruct.theshz#" />
				<!--- Extract ZIP --->
				<cfzip action="extract" zipfile="#storein#/razuna_pdf_images.zip" destination="#storein#/razuna_pdf_images" />
				<!--- Remove the ZIP file --->
				<cffile action="delete" file="#storein#/razuna_pdf_images.zip" />
			</cfif>
			<cfcatch type="any">
				<cfmail from="server@razuna.com" to="support@razuna.com" subject="error pickup from rfs" type="html"><cfdump var="#cfcatch#"></cfmail>
			</cfcatch>
		</cftry>
		<!--- Return --->
		<cfreturn />
	</cffunction>
	
</cfcomponent>