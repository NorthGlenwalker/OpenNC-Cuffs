////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                                 occ_slave_chains                               //
//                                 version 7.1035                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.                                      //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ©   2013 - 2018  OpenNC North Glenwalker                                       //
// ©   2018 -       OpenCollar North Glenwalker                                   //
//      Suport for Arms, Legs, Wings, and Tail cuffs and restrictions             //
////////////////////////////////////////////////////////////////////////////////////

// change here for OS and IW grids
key lgkTextureChain = "245ea72d-bc79-fee3-a802-8e73c0f09473"; //Default chain texture for LG/LM needs seperate key as this texture can be changed by furniture command string.
key lgkTextureRope = "9a342cda-d62a-ae1f-fc32-a77a24a85d73"; //Default rope texture for LG/LM needs seperate key as this texture can be changed by furniture command string.
key kTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473"; //Default chain texture Chainit
// Do not change anything behond here

string    g_szModToken    = "llac"; // valid token for this module, TBD need to be read more global
key g_keyWearer = NULL_KEY;  // key of the owner/wearer

// name of occ part for requesting info from the master cuff
// NOTE: for products other than cuffs this HAS to be change for the OCC names or the your items will interferre with the cuffs
list lstCuffNames=["Not","chest","skull","lshoulder","rshoulder","lhand","rhand","lfoot","rfoot","spine","ocbelt","mouth","chin","lear","rear","leye","reye","nose","ruac","rlac","luac","llac","rhip","rulc","rllc","lhip","lulc","lllc","ocbelt","rpec","lpec","HUD Center 2","HUD Top Right","HUD Top","HUD Top Left","HUD Center","HUD Bottom Left","HUD Bottom","HUD Bottom Right"];

key g_keyFirstOwner;
integer listener;
integer g_nCmdChannel;      //our normal coms channel a product of our UUID
integer g_nCmdHandle    = 0;            // command listen handler
integer g_nCmdChannelOffset = 0xCC0CC;       // offset to be used to make sure we do not interfere with other items using the same technique for

string  g_szAllowedCommadToken = "rlac"; // only accept commands from this token adress
list    g_lstModTokens    = []; // valid token for this module
integer    CMD_UNKNOWN        = -1;        // unknown command - don't handle
integer    CMD_CHAT        = 0;        // chat cmd - check what should happen with it
integer    CMD_EXTERNAL    = 1;        // external cmd - check what should happen with it
integer    CMD_MODULE        = 2;        // cmd for this module
integer    g_nCmdType        = CMD_UNKNOWN;
//
// external command syntax
// sender prefix|receiver prefix|command1=value1~command2=value2|UUID to send under
// occ|rwc|chain=on~lock=on|aaa-bbb-2222...
//
string    g_szReceiver    = "";
string    g_szSender        = "";
integer g_nLockGuardChannel = -9119;
key lgkTexture;

//Chaining
//LG/LM
integer         lmChannel = -8888; //  added channel -8888 and handler for lockmeister
integer         lglmHandle;
string          lmAttachmentpoint = "rlcuff"; // will be read on int from the Object Name
integer         lmIgnore;
list            lglCommandLine;
integer         lgParserCount;
list            LGNames = ["rcuff","lcuff","lbiceps","rbiceps","ltigh","rtigh","llcuff","rlcuff","lbelt"];
list            LGID1   = ["rightwrist","leftwrist","leftupperarm","rightupperarm","leftupperthigh","rightupperthigh","leftankle","rightankle","frontbeltloop"];
list            LGID2   = ["wrists","wrists","arms","arms","thighs","thighs","ankles","ankles"," "];
list            LGID3   = ["allfour","allfour"," "," "," "," ","allfour","allfour"," "];
list            LGOurParts; //strided list of part,link number
list            lLockGuardCommands = [ "id", "link", "unlink", "ping", "free", "texture", "size", "life", "speed", "gravity", "color", "unlisten", "channel" ];
list            lglLockGuardID;
key             lgkTarget;//texture to use for particles
integer         nLinked = FALSE;
key             fkTexture;
float           fSizeX;
float           fSizeY;
float           fLife;
float           fGravity;
float           fMinSpeed;
float           fMaxSpeed;
float           fRed;
float           fGreen;
float           fBlue;

//ChainIt
integer g_nInternalLockGuardChannel ;       //Our internal coms channel g_nCmdChannel+1
integer    g_nChainHandle        = 0;            // chain listen handler
string    g_szChainPart        = "";            // chain part - info from LockGuardPing
integer    g_nShowScript    = FALSE;
integer         nHandle;
list            lCommandLine;
integer         nParserCount;
list            llChainItCommands = ["id", "link", "unlink", "ping", "free", "texture", "size", "life", "speed", "gravity", "color", "unlisten", "channel"];
list            llChainItID = ["occuffs"];
key             kTarget;

//==================================================
//  particle chain
//==================================================

string g_sRibbonTexture;
string g_sClassicTexture;
custom()
{
    integer iNumberOfTextures = llGetInventoryNumber(INVENTORY_TEXTURE);
    integer iLeashTexture;
    integer g_iLoop;
    for (g_iLoop =0 ; g_iLoop < iNumberOfTextures; ++g_iLoop)
    {
        string sName = llGetInventoryName(INVENTORY_TEXTURE, g_iLoop);
        if (llToLower(llGetSubString(sName,0,6)) == "!ribbon")
            g_sRibbonTexture = sName;
        else if (llToLower(llGetSubString(sName,0,7)) == "!classic")
            g_sClassicTexture = sName;
    }
}

Linking (integer n, key Target )
{//llOwnerSay( (string) n + " " +(string) Target);
    integer nBitField = PSYS_PART_TARGET_POS_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK;
    if (g_sClassicTexture != "")
        fkTexture = g_sClassicTexture;
    if (g_sRibbonTexture != "")
    {
        fkTexture = g_sRibbonTexture;
        nBitField = nBitField | PSYS_PART_RIBBON_MASK;
    }
    
    llLinkParticleSystem(n, [] );
        
    llLinkParticleSystem(n, [ PSYS_PART_MAX_AGE, fLife, PSYS_PART_FLAGS, nBitField, PSYS_PART_START_COLOR, <fRed,fGreen,fBlue>, PSYS_PART_END_COLOR, <fRed,fGreen,fBlue>, PSYS_PART_START_SCALE, <fSizeX, fSizeY, 1>, PSYS_PART_END_SCALE, <fSizeX, fSizeY, 1>, PSYS_SRC_PATTERN, 1, PSYS_SRC_BURST_RATE, 0.000000, PSYS_SRC_ACCEL, <0.00000, 0.00000, (fGravity*-1)>, PSYS_SRC_BURST_PART_COUNT, 1, PSYS_SRC_BURST_RADIUS, 0.000000, PSYS_SRC_BURST_SPEED_MIN, fMinSpeed, PSYS_SRC_BURST_SPEED_MAX, fMaxSpeed, PSYS_SRC_INNERANGLE, 0.000000, PSYS_SRC_OUTERANGLE, 0.000000, PSYS_SRC_OMEGA, <0.00000, 0.00000, 0.00000>, PSYS_SRC_MAX_AGE, 0.000000, PSYS_PART_START_ALPHA, 1.000000, PSYS_PART_END_ALPHA, 1.000000, PSYS_SRC_TARGET_KEY,Target, PSYS_SRC_TEXTURE, fkTexture ] );

    nLinked = TRUE;
}

//LG/LM chaining start
lgSanity(string message)
{
    lglCommandLine = llParseString2List( llToLower( message ), [ " " ], [] );
    if( !llLockGuardItemCheck() )
        return;
    llLockGuardObey();
}

FindParts()
{
    LGOurParts = [];
    integer n;
    integer linkcount = llGetNumberOfPrims();
    for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
    {
        string getname =  llGetLinkName(n); // get Name of ocAttachmentPoint from prims
        integer m = llListFindList(LGNames,[getname]);
        if( m != -1 )//find any LG prims and record the prim number
        {
            LGOurParts += [getname,n]; //just add our attach point names
            lmAttachmentpoint = getname;
            lglLockGuardID = [llList2String(LGID1,m),llList2String(LGID2,m),llList2String(LGID3,m)];
        }
    }
}

llLockGuardTexture()
{
    fkTexture = llList2Key( lCommandLine, ++nParserCount );
    if( kTexture == "chain" )
        fkTexture = lgkTextureChain;
    if( kTexture == "rope" )
        fkTexture = lgkTextureRope;
}

llLockGuardSize()
{
    fSizeX = llList2Float( lCommandLine, ++nParserCount );
    fSizeY = llList2Float( lCommandLine, ++nParserCount );
}

llLockGuardLife()
{
    fLife = llList2Float( lCommandLine, ++nParserCount );
}

llLockGuardSpeed()
{
    fMinSpeed = llList2Float( lCommandLine, ++nParserCount );
    fMaxSpeed = llList2Float( lCommandLine, ++nParserCount );
}

llLockGuardGravity()
{
    fGravity = llList2Float( lCommandLine, ++nParserCount );
}

llLockGuardColor()
{
    fRed = llList2Float( lCommandLine, ++nParserCount );
    fGreen = llList2Float( lCommandLine, ++nParserCount );
    fBlue = llList2Float( lCommandLine, ++nParserCount );
}

integer llLockGuardItemCheck()
{
    if( llList2String( lglCommandLine, 0 ) != "lockguard" )
        return FALSE;
    if( llList2String( lglCommandLine, 1 ) != (string)llGetOwner() )
        return FALSE;
    if( llList2String( lglCommandLine, 2 ) == "allfour" )
        return TRUE;
    if( llList2String( lglCommandLine, 2 ) == "all" && llList2String( lglCommandLine, 3 ) == "unlink")
        return TRUE;
    if( llListFindList( lglLockGuardID, llList2List( lglCommandLine, 2, 2 ) ) == -1 )
        return FALSE;
    return TRUE;
}

llLockGuardUnlink(integer n)
{
    llLinkParticleSystem(n, [] );
    nLinked = FALSE;
    lgkTarget = NULL_KEY;
}

llLockGuardObey()
{
    //set LockMeister to ignore so we ignore LM messages for 2 seconds for duel LG/LM furniture
    llSetTimerEvent(2);
    lmIgnore = TRUE;
    //set up defaults before they get changed by the command line
    fkTexture = lgkTextureChain;
    fSizeX = 0.07;
    fSizeY = 0.07;
    fLife = 1;
    fGravity = 0.3;
    fMinSpeed = 0.005;
    fMaxSpeed = 0.005;
    fRed = 1;
    fGreen = 1;
    fBlue = 1;
//    llOwnerSay(llList2CSV(lglCommandLine));
    integer nCommands = llGetListLength( lglCommandLine );   
    integer nReturn;
    integer n = llList2Integer(LGOurParts,1);
    lgParserCount = 3;//so we start at 3 in the LG command string
    do
    {
        nReturn = llListFindList( lLockGuardCommands, llList2List( lglCommandLine, lgParserCount, lgParserCount ) );
        if( nReturn == 1 )
        {
            integer y = llListFindList(lglCommandLine,["link"]);
            lgkTarget = llList2Key( lglCommandLine, y + 1 );
            Linking(n , lgkTarget);// format -  prim link number, lgtarket again??, texture to use
        }
        else if( nReturn == 2 )
            llLockGuardUnlink(n);
        if( nReturn == 3 )
            llWhisper( g_nLockGuardChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " okay" );
        if( nReturn == 4 )
        {
            if( nLinked )
                llWhisper( g_nLockGuardChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " no" );
            else
                llWhisper( g_nLockGuardChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " yes" );   
        }
        //************************Check all chain commands work else use from below more need to check color texture/life etc works through now
        if( nReturn == 5 )
            llLockGuardTexture();
        if( nReturn == 6 )
            llLockGuardSize();
        if( nReturn == 7 )
            llLockGuardLife();
        if( nReturn == 8 )
            llLockGuardSpeed();
        if( nReturn == 9 )
            llLockGuardGravity();
        if( nReturn == 10 )
            llLockGuardColor();
        
/*        if( nReturn == 1 )//lets link the chain but we need to find the destination first
        {
            integer y = llListFindList(lglCommandLine,["link"]);
            lgkTarget = llList2Key( lglCommandLine, y + 1 );
            Linking(n , lgkTarget, lgkTexture);// format -  prim link number, lgtarket again??, texture to use
        }
        else if( nReturn == 2 ) //we got a request to unlink the chain
            llLockGuardUnlink(n);
        else if( nReturn == 3 )// we got a ping command
            llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " okay" );
        else if( nReturn == 4 )//we got a request if we are a free point
        {
            if( nLinked )
                llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " no" );
            else
                llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " yes" );   
        }
        if( nReturn == 5 )//section copied here from below ?????? just to test
        {
            integer x = llListFindList(lglCommandLine,["texture"]);
            string xs = llList2String( lglCommandLine, x +1 );
            if( xs == "chain")
                lgkTexture = lgkTextureChain;
            else if( xs == "rope")
                lgkTexture = lgkTextureRope;
            else if ( llStringLength (xs) == 36) // a valid UUID length
                lgkTexture = xs;//make it our new texture
        }*/
        lgParserCount++;
    }
    while( lgParserCount < nCommands );
}
// end of LG chaining parts
//build a list of ChainIt chaining points
chain_points()
{
    llChainItID = [];
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

ChainItObey()
{//set up defaults before they get changed by the command line
    fkTexture = kTexture;
    fSizeX = 0.07;
    fSizeY = 0.07;
    fLife = 0.5;
    fGravity = 0.3;
    fMinSpeed = 0.005;
    fMaxSpeed = 0.005;
    fRed = 1;
    fGreen = 1;
    fBlue = 1;
    nParserCount = 0;
    integer nCommands = llGetListLength( lCommandLine );
    integer nReturn;
    integer n;
    integer linkcount = llGetNumberOfPrims();
    do
    {
        nReturn = llListFindList( llChainItCommands, llList2List( lCommandLine, nParserCount, nParserCount ) );
//        if( nReturn == 1 )
//            llLockGuardLink( FALSE );
//        if( nReturn == 2 )
//            llLockGuardUnlink();
/*        if( nReturn == 3 ) /// Do we need this section as it's chainit not LG
            llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( llList2List( lCommandLine, nParserCount, nParserCount ), 0 ) + " okay" );
        else if( nReturn == 4 )
        {
            if( nLinked )
                llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( llList2List( lCommandLine, nParserCount, nParserCount ), 0 ) + " no" );
            else
                llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( llList2List( lCommandLine, nParserCount, nParserCount ), 0 ) + " yes" );
        }
//        else if( nReturn == 5 )
//            llLockGuardTexture();
        else*/ if( nReturn == 6 )
            llLockGuardSize();
        else if( nReturn == 7 )
            llLockGuardLife();
        else if( nReturn == 8 )
            llLockGuardSpeed();
        else if( nReturn == 9 )
            llLockGuardGravity();
        else if( nReturn == 10 )
            llLockGuardColor();
            
        else if( nReturn == 1 )
        {
            for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
            {
                string getname =  (string)llGetLinkPrimitiveParams(n,[PRIM_NAME]); // get Name of ocAttachmentPoint from prims
                if(llListFindList(llChainItID, [getname]) != -1 && llListFindList(lCommandLine,[getname]) != -1)//find the chaining point prim we need && chainng point is in list to chain to
                {
                    kTarget = llList2Key( lCommandLine, ++nParserCount );
                    Linking( n , kTarget);
                }
            }
        }
        else if( nReturn == 2 )
        {
            for (n = 2; n <= linkcount; n++) //start at 2 as root is 1
            {
                string getname =  (string)llGetLinkPrimitiveParams(n,[PRIM_NAME]); // get Name of ocAttachmentPoint from prims
                if(llListFindList(llChainItID, [getname]) != -1)//find the chaining point prim we need
                    llLinkParticleSystem(n, [] );//do a chain particles
            }
        }
        else if( nReturn == 5 )
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
    if ( szCmd == "chain" )
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
                        if (szLink == "unlink" ||  szLink == "link" )
                            llWhisper( g_nInternalLockGuardChannel, "lockguard " + (string)g_keyWearer + " " + szChain + " " + szLink + " " + (string)llGetLinkKey(n) );
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

SendCmd( string szSendTo, string keyID)
{
    llWhisper(g_nCmdChannel, llList2String(g_lstModTokens,0) + "|" + szSendTo + "|" + keyID + "|" + keyID);//send our attach ID (eg llac)
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
    return szCmd;
}

ParseCmdString( key keyID, string szMsg )
{
    list    lstParsed = llParseString2List( szMsg, [ "~" ], [] );
    integer nCnt = llGetListLength(lstParsed);
    integer i = 0;
    for (i = 0; i < nCnt; i++ )
        ParseSingleCmd(keyID, llList2String(lstParsed, i));
}

ParseSingleCmd( key keyID, string szMsg )
{
    list    lstParsed    = llParseString2List( szMsg, [ "=" ], [] );
    string    szCmd    = llList2String(lstParsed,0);
    string    szValue    = llList2String(lstParsed,1);
    integer length = llGetListLength(lstParsed);
    if ( szCmd == "chain" )
    {
        if (( length == 4 || length == 7 ) && llGetKey() != keyID )//check string length and we didn't originally sent this command
            Sanity2( szMsg );
    }
}

string Float2String(string out)
{
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0")
        out = llGetSubString(out, 0, -2);
    return out;
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
    g_szModToken=llList2String(lstCuffNames,llGetAttached());
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
            llLinkParticleSystem(n, [] );//clear any chain particles
    }
    FindParts();
    //adding lockmeistersupport
    lglmHandle = llListen( lmChannel, "", NULL_KEY, (string)llGetOwner() + lmAttachmentpoint);
    custom();
}

default
{
    state_entry()
    {
        Init(); 
    }

    on_rez(integer param)
    {
        llLockGuardUnlink(llList2Integer(LGOurParts,1));
        if (llGetAttached() == 0) // If not attached then
        {
            llResetScript();
            return;
        }
        
        if (g_keyWearer == llGetOwner())
        {
            Init();// we keep loosing who we are so main cuff won't hear us
        }
        else
            llResetScript();
    }

    listen(integer nChannel, string szName, key keyID, string szMsg)
    {
        szMsg = llStringTrim(szMsg, STRING_TRIM);
        if(nChannel == lmChannel && lmIgnore == FALSE)//LockMeister ignore messages if sent from LG/LM dual furniture
            llWhisper(lmChannel,(string)llGetOwner() + lmAttachmentpoint + " ok");
        // commands sent on cmd channel
        if ( nChannel == g_nInternalLockGuardChannel )
        {
            if ( IsAllowed(keyID) )
            {
                if (llGetSubString(szMsg,0,8)=="lockguard")
                    Sanity1( szMsg );
                else
                { // check if external or maybe for this module
                    string szCmd = CheckCmd( keyID, szMsg );
                    if ( g_nCmdType == CMD_MODULE )
                        ParseCmdString(keyID, szCmd);
                }
            }
        } 
        else if ( nChannel == g_nLockGuardChannel)// LG channel message received split into ChainIt or LG message
        {
            Sanity1(szMsg);
            lgSanity(szMsg);
        }
    }
    
    timer()
    {
        llSetTimerEvent(0);
        lmIgnore = FALSE;
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
            custom();
    }
}
