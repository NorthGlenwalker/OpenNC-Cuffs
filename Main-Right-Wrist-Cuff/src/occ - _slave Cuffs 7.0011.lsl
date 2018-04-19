////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenNC - _Slave Cuff                              //
//                                 version 7.0011                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.                                      //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ©   2013 - 2018  OpenNC                                                        //
//      Suport for Arms, Legs, Wings, and Tail cuffs and restrictions             //
// ------------------------------------------------------------------------------ //
// Not now supported by OpenCollar at all                                         //
////////////////////////////////////////////////////////////////////////////////////

// change here for OS and IW grids
key lgkTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473"; //Default chain texture for LG/LM
key kTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473"; //Default chain texture Chainit
// Do not change anything behond here

// name of occ part for requesting info from the master cuff
// NOTE: for products other than cuffs this HAS to be change for the OCC names or the your items will interferre with the cuffs
list lstCuffNames=["Not","chest","skull","lshoulder","rshoulder","lhand","rhand","lfoot","rfoot","spine","ocbelt","mouth","chin","lear","rear","leye","reye","nose","ruac","rlac","luac","llac","rhip","rulc","rllc","lhip","lulc","lllc","ocbelt","rpec","lpec","HUD Center 2","HUD Top Right","HUD Top","HUD Top Left","HUD Center","HUD Bottom Left","HUD Bottom","HUD Bottom Right"];

string      g_szModToken    = "rlac"; // valid token for this module, TBD need to be read more global
key         g_keyWearer = NULL_KEY;  // key of the owner/wearer
integer     LM_CUFF_CMD = -551001;
key         g_keyFirstOwner;
integer     listener;
integer     g_nCmdChannel;      //our normal coms channel a product of our UUID
integer     g_nCmdHandle    = 0;            // command listen handler
integer     g_nCmdChannelOffset = 0xCC0CC;       // offset to be used to make sure we do not interfere with other items using the same technique for
string      g_szAllowedCommadToken = "rlac"; // only accept commands from this token adress
list        g_lstModTokens    = []; // valid token for this module
integer     CMD_UNKNOWN        = -1;        // unknown command - don't handle
integer     CMD_CHAT        = 0;        // chat cmd - check what should happen with it
integer     CMD_EXTERNAL    = 1;        // external cmd - check what should happen with it
integer     CMD_MODULE        = 2;        // cmd for this module
integer     g_nCmdType        = CMD_UNKNOWN;
//
// external command syntax
// sender prefix|receiver prefix|command1=value1~command2=value2|UUID to send under
// occ|rwc|chain=on~lock=on|aaa-bbb-2222...
//
string      g_szReceiver    = "";
string      g_szSender        = "";
integer     g_nLockGuardChannel = -9119;

//Chaining
//LG/LM
integer     lmChannel = -8888; //  added channel -8888 and handler for lockmeister
integer     lglmHandle;
string      lmAttachmentpoint = "rlcuff"; // will be read on int from the Object Name
integer     mChannel = -9119;
integer     lgHandle;
string      fnLNCFilename = "LockGuard V2 Config";
string      fnLNCFileData;
list        fnLNCFileDataList;
integer     fnLNCLine;
key         fnLNCQueryID;
list        lglCommandLine;
integer     lgParserCount;
list        LGNames = ["rcuff","lcuff","lbiceps","rbiceps","ltigh","rtigh","llcuff","llcuff","lbelt"];
list        LGOurParts; //strided list of part,link number
list        lLockGuardCommands = [ "id", "link", "unlink", "ping", "free", "texture"];
list        lglLockGuardID;
key         lgkTarget;
integer     nLinked = FALSE;
//ChainIt
integer     g_nInternalLockGuardChannel ;       //Our internal coms channel g_nCmdChannel+1
integer     g_nChainHandle        = 0;            // chain listen handler
string      g_szChainPart        = "";            // chain part - info from LockGuardPing
integer     g_nShowScript    = FALSE;
integer     nHandle;
list        lCommandLine;
integer     nParserCount;
list        llChainItCommands = ["link", "unlink", "texture"];
list        llChainItID = ["occuffs"];
key         kTarget;

lgSanity(string message)
{
    lglCommandLine = llParseString2List( llToLower( message ), [ " " ], [] );
    if( !llLockGuardItemCheck() )
        return;
    llLockGuardObey( 3 );
}

FindParts()
{
    integer n;
    integer linkcount = llGetNumberOfPrims();
    for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
    {
        string getname =  llGetLinkName(n); // get Name of ocAttachmentPoint from prims
        if(llListFindList(LGNames,[getname]) != -1 )//find any LG prims and record the prim number
        {
            LGOurParts += [getname,n]; //just add our attach point names
            lmAttachmentpoint = getname;
        }
    }
}

integer llLockGuardItemCheck()
{
    if( llList2String( lglCommandLine, 0 ) != "lockguard" )
        return FALSE;
    if( llList2String( lglCommandLine, 1 ) != (string)llGetOwner() )
        return FALSE;
    if( llList2String( lglCommandLine, 2 ) == "all" )
        return TRUE;
    if( llListFindList( lglLockGuardID, llList2List( lglCommandLine, 2, 2 ) ) == -1 )
        return FALSE;
    return TRUE;
}

//==================================================
//  particle chain
//==================================================

Linking (integer lg, integer Relinking, integer n, key Target, key Texture )
{
    integer nBitField = PSYS_PART_TARGET_POS_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK;
    llLinkParticleSystem(n, [] );
    if( Relinking == FALSE && lg == TRUE)
        lgkTarget = llList2Key( lglCommandLine, ++lgParserCount );
        
    llLinkParticleSystem(n, [ PSYS_PART_MAX_AGE, 1, PSYS_PART_FLAGS, nBitField, PSYS_PART_START_COLOR, <1,1,1>, PSYS_PART_END_COLOR, <1,1,1>, PSYS_PART_START_SCALE, <0.07, 0.1, 0.5>, PSYS_PART_END_SCALE, <0.07, 0.1, 0.5>, PSYS_SRC_PATTERN, 1, PSYS_SRC_BURST_RATE, 0.000000, PSYS_SRC_ACCEL, <0.00000, 0.00000, (0.3*-1)>, PSYS_SRC_BURST_PART_COUNT, 1, PSYS_SRC_BURST_RADIUS, 0.000000, PSYS_SRC_BURST_SPEED_MIN, 0.005, PSYS_SRC_BURST_SPEED_MAX, 0.005, PSYS_SRC_INNERANGLE, 0.000000, PSYS_SRC_OUTERANGLE, 0.000000, PSYS_SRC_OMEGA, <0.00000, 0.00000, 0.00000>, PSYS_SRC_MAX_AGE, 0.000000, PSYS_PART_START_ALPHA, 1.000000, PSYS_PART_END_ALPHA, 1.000000, PSYS_SRC_TARGET_KEY,Target, PSYS_SRC_TEXTURE, Texture ] );

    nLinked = TRUE;
}

llLockGuardUnlink()
{
    integer n = llList2Integer(LGOurParts,1);
    llLinkParticleSystem(n, [] );
    nLinked = FALSE;
    lgkTarget = NULL_KEY;
}

llLockGuardObey( integer fn_nBase )
{
    integer nCommands = llGetListLength( lglCommandLine );   
    integer nReturn;
    lgParserCount = fn_nBase;
    do
    {
        nReturn = llListFindList( lLockGuardCommands, llList2List( lglCommandLine, lgParserCount, lgParserCount ) );
        if( fn_nBase == 3 )
        {
            if( nReturn == 1 )
            {
                integer n = llList2Integer(LGOurParts,1);
                Linking(TRUE, FALSE, n , lgkTarget, lgkTexture);
            }
            else if( nReturn == 2 ) 
                llLockGuardUnlink();
            else if( nReturn == 3 )
                llWhisper( mChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " okay" );
            else if( nReturn == 4 )
            {
                if( nLinked )
                    llWhisper( mChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " no" );
                else
                    llWhisper( mChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " yes" );   
            }
        }
        if( nReturn == 5 )
        {
            lgkTexture = llList2Key( lglCommandLine, ++lgParserCount );
            if( nLinked )
            {
                integer n = llList2Integer(LGOurParts,1);
                Linking(TRUE, TRUE, n , lgkTarget, lgkTexture);
            }
        }
        if( fn_nBase == 0 && nReturn == 0 )
            lglLockGuardID += llList2List( lglCommandLine, ++lgParserCount, ++lgParserCount );
        lgParserCount++;
    }
    while( lgParserCount < nCommands );
}
// end of LG chaining parts
//build a list of ChainIt chaining points
chain_points()
{
    integer n;
    integer linkcount = llGetNumberOfPrims();
    for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
    {
        string getname =  llGetLinkName(n); // get Name of ocAttachmentPoint from prims
        string sub_getname  = llGetSubString(getname, -4,-1);
        string sub_getname1  = llGetSubString(getname, -6,-1);
        if(llListFindList(lstCuffNames,[sub_getname]) != -1 || sub_getname1 == "ocbelt")//most are 5 long ocbelt is 6 long total
            llChainItID += getname; //just add our attach point names
    }
    g_lstModTokens += llChainItID; // yes we need this as well as it uses the attach point as well to send which is first in it's list
}

integer g_szChainPart_find(string to_find)
{
    if(llListFindList(llChainItID,[to_find]) != -1)
    {
        g_szChainPart = to_find;
        return TRUE;
    }
    else
        return FALSE;
}

integer ChainItItemCheck()
{
    if( llList2String( lCommandLine, 0 ) != "lockguard" )
        return FALSE;
    if( llList2String( lCommandLine, 1 ) != (string)g_keyWearer )
        return FALSE;
    if( llList2String( lCommandLine, 2 ) == "all" )
        return TRUE;
    if( llListFindList( llChainItID, llList2List( lCommandLine, 2, 2 ) ) == -1 )
        return FALSE;
    return TRUE;
}

ChainItUnlink(integer prim)
{
    llLinkParticleSystem(prim, [] );
    kTarget = NULL_KEY;
}

ChainItObey()
{
    nParserCount = 0;
    integer nCommands = llGetListLength( lCommandLine );
    integer nReturn;
    do
    {
        nReturn = llListFindList( llChainItCommands, llList2List( lCommandLine, nParserCount, nParserCount ) );
        if( nReturn == 0 )
        {
            integer n;
            integer linkcount = llGetNumberOfPrims();
            for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
            {
                string getname =  (string)llGetLinkPrimitiveParams(n,[PRIM_NAME]); // get Name of ocAttachmentPoint from prims
                if(llListFindList(llChainItID, [getname]) != -1 && llListFindList(lCommandLine,[getname]) != -1)//find the chaining point prim we need && chainng point is in lsit to chain to
                {
                    kTarget = llList2Key( lCommandLine, ++nParserCount );
                    Linking(FALSE, FALSE, n , kTarget, kTexture);
                }
            }
        }
        else if( nReturn == 1 )
        {
            integer n;
            integer linkcount = llGetNumberOfPrims();
            for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
            {
                string getname =  (string)llGetLinkPrimitiveParams(n,[PRIM_NAME]); // get Name of ocAttachmentPoint from prims
                if(llListFindList(llChainItID, [getname]) != -1)//find the chaining point prim we need
                    llLinkParticleSystem(n, [] );//do a chain particles
            }
        }
        else if( nReturn == 2 )
            kTexture = llList2String(lCommandLine,4);//we are being sent a texture for the chains
        nParserCount++;
    }
    while( nParserCount < nCommands );
}

Sanity1(string message)
{
    lCommandLine = llParseString2List( llToLower( message ), [ " " ], [] );
    if( !ChainItItemCheck() )
        return;
    ChainItObey();
}

Sanity2(string message)
{
    list    lstParsed    = llParseString2List( message, [ "=" ], [] );
    string    szCmd        = llList2String(lstParsed,0);
    key        keyOwner    = llList2Key(lstParsed,1);
    if ( szCmd == "chain" ) //&& llList2String(lstParsed,1) == g_szChainPart )
    {
        if ( llGetListLength(lstParsed) == 4 )
        {
            string    szCaller = llList2String(lstParsed,1);
            string    szChain    = llList2String(lstParsed,2);
            string    szLink    = llList2String(lstParsed,3);
            if ( g_szChainPart_find(szCaller) || szCaller == "*" ) // check this is for us first
            {
                integer n;
                integer linkcount = llGetNumberOfPrims();
                for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
                {
                    string getname =  llGetLinkName(n); // get Name of ocAttachmentPoint from prims
                    if(llListFindList(lstParsed,[getname]) != -1)//
                    {
                        if (szLink == "unlink" || szLink == "link" )
                            llWhisper( g_nInternalLockGuardChannel, "lockguard " + (string)g_keyWearer + " " + szChain + " " + szLink + " " + (string)llGetLinkKey(n));
                        else if (llGetSubString(szLink,0,3)=="link" && (llStringLength(szLink)>5))
                        {
                            string s="lockguard " + (string)g_keyWearer + " " + szChain + " " + llGetSubString(szLink,5,-1)+" link "+(string)llGetLinkKey(n);
                            llWhisper( g_nInternalLockGuardChannel,s);
                        }
                    }
                }
            }

        }
    }
}
//End of ChainIt chaining points
//End of chaining

SendCmd( string szSendTo, string szCmd, key keyID ) //this is not the same format as SendCmd1
{
    llWhisper(g_nCmdChannel, g_szModToken + "|" + szSendTo + "|" + szCmd + "|" + (string)keyID);
}

integer nGetOwnerChannel(integer nOffset)
{
    integer chan = (integer)("0x"+llGetSubString((string)g_keyWearer,3,8)) + g_nCmdChannelOffset;
    if (chan>0)
        chan=chan*(-1);
    if (chan > -10000)
        chan -= 30000;
    return chan;
}

integer nStartsWith(string szHaystack, string szNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return (llDeleteSubString(szHaystack, llStringLength(szNeedle), -1) == szNeedle);
}

string GetCuffName()
{
    return llList2String(lstCuffNames,llGetAttached());
}

string szStripSpaces (string szStr)
{
    return llDumpList2String(llParseString2List(szStr, [" "], []), "");
}

integer IsAllowed( key keyID )
{
    integer nAllow = FALSE;

    if ( llGetOwnerKey(keyID) == g_keyWearer )
        nAllow = TRUE;
    return nAllow;
}

string CheckCmd( key keyID, string szMsg )
{
    list lstParsed = llParseString2List( szMsg, [ "|" ], [] );
    string szCmd = szMsg;
    // first part should be sender token
    // second part the receiver token
    // third part = command
    if ( llGetListLength(lstParsed) > 2 )
    {
        // check the sender of the command occ,rwc,...
        g_szSender = llList2String(lstParsed,0);
        g_nCmdType = CMD_UNKNOWN;
        if ( g_szSender==g_szAllowedCommadToken ) // only accept command from the master cuff
        {
            g_nCmdType = CMD_EXTERNAL;
            g_szReceiver = llList2String(lstParsed,1);// cap and store the receiver
            if ( (llListFindList(g_lstModTokens,[g_szReceiver]) != -1) || g_szReceiver == "*" )// we are the receiver
            {
                // set cmd return to the rest of the command string
                szCmd = llList2String(lstParsed,2);
                g_nCmdType = CMD_MODULE;
            }
        }
    }
    lstParsed = [];
    return szCmd;
}

ParseCmdString( key keyID, string szMsg )
{
    list    lstParsed = llParseString2List( szMsg, [ "~" ], [] );
    integer nCnt = llGetListLength(lstParsed);
    integer i = 0;
    for (i = 0; i < nCnt; i++ )
        ParseSingleCmd( llList2String(lstParsed, i));
    lstParsed = [];
}

ParseSingleCmd(string szMsg )
{
    list    lstParsed    = llParseString2List( szMsg, [ "=" ], [] );
    string    szCmd    = llList2String(lstParsed,0);
    string    szValue    = llList2String(lstParsed,1);
    integer length = llGetListLength(lstParsed);
    if ( szCmd == "chain" )
    {
        if ( length == 4 || length == 7 )
            Sanity2( szMsg );
    }
    lstParsed = [];
}

Init()
{   
    g_keyWearer = llGetOwner();
    // get unique channel numbers for the command and cuff channel, cuff channel wil be used for LG chains of cuffs as well
    g_nCmdChannel = nGetOwnerChannel(g_nCmdChannelOffset);
    g_nInternalLockGuardChannel=g_nCmdChannel+1;
    llListenRemove(g_nCmdHandle);
    g_nCmdHandle = llListen(g_nInternalLockGuardChannel, "", NULL_KEY, "");
    g_lstModTokens = (list)llList2String(lstCuffNames,llGetAttached()); // get name of the cuff from the attachment point, this is absolutly needed for the system to work, other chain point wil be received via LMs
    g_szModToken=GetCuffName();
    // listen to LockGuard requests
    llListen(g_nLockGuardChannel,"","","");
    
    chain_points();//build a list of chain points
    //clear all existing chain points
    integer n;
    integer linkcount = llGetNumberOfPrims();
    for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
    {
        string getname =  (string)llGetLinkPrimitiveParams(n,[PRIM_NAME]); // get Name of ocAttachmentPoint from prims
        if(llListFindList(llChainItID, [getname]) != -1)//find the chaining point prim we need
            ChainItUnlink(n);//clear any chain particles
    }
}

default
{
    state_entry()
    {
        Init();
        fnLNCLine = 0;
        fnLNCQueryID = llGetNotecardLine( fnLNCFilename, fnLNCLine );
        lglmHandle = llListen( lmChannel, "", NULL_KEY, (string)llGetOwner() + lmAttachmentpoint);
    }

    on_rez(integer param)
    {
        llLockGuardUnlink();
        if (llGetAttached() == 0) // If not attached then
        {
            llResetScript();
            return;
        }
        
        if (g_keyWearer == llGetOwner())
            Init();// we keep loosing who we are so main cuff won't hear us
        else
            llResetScript();
    }
    
    link_message(integer sender, integer nNum, string str, key id)
    {
        string szCmd = llToLower(llStringTrim(str, STRING_TRIM));
        if(nNum == LM_CUFF_CMD)
            ParseCmdString(id, szCmd);
        if(nNum == mChannel)
            Sanity1(str);
    }

    listen(integer nChannel, string szName, key keyID, string szMsg)//this can not hear it's self!
    {
        szMsg = llStringTrim(szMsg, STRING_TRIM);
        if(nChannel == lmChannel)
            llWhisper(lmChannel,(string)llGetOwner() + lmAttachmentpoint + " ok");
        // commands sent on cmd channel
        if ( nChannel == g_nInternalLockGuardChannel )
        {
            if ( IsAllowed(keyID) )
            {
                if (llGetSubString(szMsg,0,8)=="lockguard")
                    Sanity1( szMsg );
            }
        } 
        else if ( nChannel == g_nLockGuardChannel)// LG channel message received split into ChainIt or LG message
            lgSanity(szMsg);
    }
    
    dataserver( key query_id, string data )
    {
        integer i;
        if( query_id == fnLNCQueryID )
        {
            if( data != EOF )
            {
                if( fnLNCLine > 0 )
                    fnLNCFileData += " ";
                else
                    fnLNCFileDataList = [];
                fnLNCFileDataList += [ data ];
                fnLNCLine++;
                fnLNCQueryID = llGetNotecardLine( fnLNCFilename, fnLNCLine );
            }
            else
            {
                do
                {
                    lCommandLine = llParseString2List( llToLower( llList2String( fnLNCFileDataList, i ) ), [ " " ], [] );
                    llLockGuardObey( 0 );
                    i++;
                }
                while( i < llGetListLength( fnLNCFileDataList ) )
                    ;
                fnLNCFileDataList = [];
            }
        }
    }
}