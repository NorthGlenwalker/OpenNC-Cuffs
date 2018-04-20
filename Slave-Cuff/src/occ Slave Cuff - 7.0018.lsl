////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                                occ - Slave Cuff                                //
//                                 version 7.0018                                 //
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
key lgkTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473"; //Default chain texture for LG/LM needs seperate key as this texture can be changed by furniture command string.
key kTexture = "245ea72d-bc79-fee3-a802-8e73c0f09473"; //Default chain texture Chainit
// Do not change anything behond here

string    g_szModToken    = "llac"; // valid token for this module, TBD need to be read more global
key g_keyWearer = NULL_KEY;  // key of the owner/wearer
// Messages to be received
string g_szLockCmd="Lock"; // message for setting lock on or off
string g_szInfoRequest="SendLockInfo"; // request info about RLV and Lock status from main cuff

// name of occ part for requesting info from the master cuff
// NOTE: for products other than cuffs this HAS to be change for the OCC names or the your items will interferre with the cuffs
list lstCuffNames=["Not","chest","skull","lshoulder","rshoulder","lhand","rhand","lfoot","rfoot","spine","ocbelt","mouth","chin","lear","rear","leye","reye","nose","ruac","rlac","luac","llac","rhip","rulc","rllc","lhip","lulc","lllc","ocbelt","rpec","lpec","HUD Center 2","HUD Top Right","HUD Top","HUD Top Left","HUD Center","HUD Bottom Left","HUD Bottom","HUD Bottom Right"];

integer g_nLocked=FALSE; // is the cuff locked
integer g_nUseRLV=FALSE; // should RLV be used
integer g_nLockedState=FALSE; // state submitted to RLV viewer
string g_szIllegalDetach="";
key g_keyFirstOwner;
integer listener;
integer g_nCmdChannel;      //our normal coms channel a product of our UUID
integer g_nCmdHandle    = 0;            // command listen handler
integer g_nCmdChannelOffset = 0xCC0CC;       // offset to be used to make sure we do not interfere with other items using the same technique for

string g_szColorChangeCmd="ColorChanged";
string g_szTextureChangeCmd="TextureChanged";
string g_szHideCmd="HideMe"; // Comand for Cuffs to hide
integer g_nHidden=FALSE;
list TextureElements;
list ColorElements;
list textures;
list colorsettings;
list g_lAlphaSettings;
string g_sIgnore = "nohide";

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

//resizer adjust
float MIN_DIMENSION=0.001; // the minimum scale of a prim allowed, in any dimension
float MAX_DIMENSION=1.0; // the maximum scale of a prim allowed, in any dimension
float max_scale;
float min_scale;
float   cur_scale = 1.0;
integer handle;
integer menuChan;
float min_original_scale=10.0; // minimum x/y/z component of the scales in the linkset
float max_original_scale=0.0; // minimum x/y/z component of the scales in the linkset
list link_scales = [];
list link_positions = [];
integer show_size = TRUE;
 
makeMenu()
{
    llDialog(llGetOwner(),"Max scale: "+(string)max_scale+"\nMin scale: "+(string)min_scale+"\n \nCurrent scale: "+
        (string)cur_scale,["-0.01","-0.05","MIN  SIZE","+0.01","+0.05","MAX  SIZE","-0.10","-0.25","RESTORE","+0.10","+0.25"],menuChan);
}
 
integer scanLinkset()
{
    integer link_qty = llGetNumberOfPrims();
    integer link_idx;
    vector link_pos;
    vector link_scale;
    //script made specifically for linksets, not for single prims
    if (link_qty > 1)
    {
        //link numbering in linksets starts with 1
        for (link_idx=1; link_idx <= link_qty; link_idx++)
        {
            link_pos=llList2Vector(llGetLinkPrimitiveParams(link_idx,[PRIM_POSITION]),0);
            link_scale=llList2Vector(llGetLinkPrimitiveParams(link_idx,[PRIM_SIZE]),0);
            // determine the minimum and maximum prim scales in the linkset,
            // so that rescaling doesn't fail due to prim scale limitations
            if(link_scale.x<min_original_scale) min_original_scale=link_scale.x;
            else if(link_scale.x>max_original_scale) max_original_scale=link_scale.x;
            if(link_scale.y<min_original_scale) min_original_scale=link_scale.y;
            else if(link_scale.y>max_original_scale) max_original_scale=link_scale.y;
            if(link_scale.z<min_original_scale) min_original_scale=link_scale.z;
            else if(link_scale.z>max_original_scale) max_original_scale=link_scale.z;
            link_scales    += [link_scale];
            link_positions += [(link_pos-llGetRootPosition())/llGetRootRotation()];
        }
    }
    else
        return FALSE;// llOwnerSay("error: this script doesn't work for non-linked objects");
    max_scale = MAX_DIMENSION/max_original_scale;
    min_scale = MIN_DIMENSION/min_original_scale;
    return TRUE;
}
 
resizeObject(float scale)
{
    integer link_qty = llGetNumberOfPrims();
    integer link_idx;
    vector new_size;
    vector new_pos;
    if (link_qty > 1)
    {
        //link numbering in linksets starts with 1
        for (link_idx=1; link_idx <= link_qty; link_idx++)
        {
            new_size   = scale * llList2Vector(link_scales, link_idx-1);
            new_pos    = scale * llList2Vector(link_positions, link_idx-1);
 
            if (link_idx == 1)
                llSetLinkPrimitiveParamsFast(link_idx, [PRIM_SIZE, new_size]);//because we don't really want to move the root prim as it moves the whole object
            else
                llSetLinkPrimitiveParamsFast(link_idx, [PRIM_SIZE, new_size, PRIM_POSITION, new_pos]);
        }
    }
}
//end of size adjust

//Chaining
//LG/LM
integer         lmChannel = -8888; //  added channel -8888 and handler for lockmeister
integer         lglmHandle;
string          lmAttachmentpoint = "rlcuff"; // will be read on int from the Object Name
integer         nChannel = -9119;
integer         lgHandle;
list            lglCommandLine;
integer         lgParserCount;
list            LGNames = ["rcuff","lcuff","lbiceps","rbiceps","ltigh","rtigh","llcuff","lrcuff","lbelt"];
list            LGID1   = ["rightwrist","leftwrist","leftupperarm","rightupperarm","leftupperthigh","rightupperthigh","leftankle","rightankle","frontbeltloop"];
list            LGID2   = ["wrists","wrists","arms","arms","thighs","thighs","ankles","ankles"," "];
list            LGOurParts; //strided list of part,link number
list            lLockGuardCommands = [ "id", "link", "unlink", "ping", "free", "texture"];
list            lglLockGuardID;
key             lgkTarget;

integer         nLinked = FALSE;
//ChainIt
integer g_nInternalLockGuardChannel ;       //Our internal coms channel g_nCmdChannel+1
integer    g_nChainHandle        = 0;            // chain listen handler
string    g_szChainPart        = "";            // chain part - info from LockGuardPing
integer    g_nShowScript    = FALSE;
integer         nHandle;
list            lCommandLine;
integer         nParserCount;
list            llChainItCommands = ["link", "unlink", "texture"];
list            llChainItID = ["occuffs"];
key             kTarget;
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

//LG/LM chaining start

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
        integer m = llListFindList(LGNames,[getname]);
        if( m != -1 )//find any LG prims and record the prim number
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
                llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " okay" );
            else if( nReturn == 4 )
            {
                if( nLinked )
                    llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " no" );
                else
                    llWhisper( nChannel, "lockguard " + (string)llGetOwner() + " " +  llList2String( lglLockGuardID, 0 ) + " yes" );   
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

SetLocking()
{
    if (g_nLocked)
    {// lock or unlock cuff as needed in RLV
        if ((!g_nLockedState && g_nUseRLV) || (g_nLockedState && g_nUseRLV))
        {
            g_nLockedState=TRUE;
            llOwnerSay("@detach=n");
        }
        else if (g_nLockedState && !g_nUseRLV)
            llOwnerSay("@detach=y");
    }
    else
    {
        if (g_nLockedState)
            g_nLockedState=FALSE;
        llOwnerSay("@detach=y");
    }
}

string szStripSpaces (string szStr)
{
    return llDumpList2String(llParseString2List(szStr, [" "], []), "");
}

string ElementTextureType(integer linknumber)
{
    string desc = (string)llGetObjectDetails(llGetLinkKey(linknumber), [OBJECT_DESC]);
    //prim desc will be elementtype~notexture(maybe)
    list params = llParseString2List(desc, ["~"], []);
    if (~llListFindList(params, ["notexture"]) || desc == "" || desc == " " || desc == "(No Description)")
        return "notexture";
    else
        return llList2String(llParseString2List(desc, ["~"], []), 0);
}

BuildTextureList()
{ //loop through non-root prims, build element list
    integer n;
    integer linkcount = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    for (n = 2; n <= linkcount; n++)
    {
        string element = ElementTextureType(n);
        if (!(~llListFindList(TextureElements, [element])) && element != "notexture")
            TextureElements += [element];
    }
}

SetElementTexture(string element, key tex)
{
    integer i=llListFindList(textures,[element]);
    if ((i==-1)||(llList2Key(textures,i+1)!=tex))
    {
        integer n;
        integer linkcount = llGetNumberOfPrims();
        for (n = 2; n <= linkcount; n++)
        {
            string thiselement = ElementTextureType(n);
            if (thiselement == element)
                llSetLinkTexture(n, tex, ALL_SIDES); //set link to new texture
        }
        //change the textures list entry for the current element
        integer index;
        index = llListFindList(textures, [element]);
        if (index == -1)
            textures += [element, tex];
        else
            textures = llListReplaceList(textures, [tex], index + 1, index + 1);
    }
}

string ElementColorType(integer linknumber)
{
    string desc = (string)llGetObjectDetails(llGetLinkKey(linknumber), [OBJECT_DESC]);
    //each prim should have <elementname> in its description, plus "nocolor" or "notexture", if you want the prim to 
    //not appear in the color or texture menus
    list params = llParseString2List(desc, ["~"], []);
    if (~llListFindList(params, ["nocolor"]) || desc == "" || desc == " " || desc == "(No Description)")
        return "nocolor";
    else
        return llList2String(params, 0);
}

BuildColorElementList()
{
    integer n;
    integer linkcount = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    for (n = 2; n <= linkcount; n++)
    {
        string element = ElementColorType(n);
        if (!(~llListFindList(ColorElements, [element])) && element != "nocolor")
            ColorElements += [element];
    }
}

SetElementColor(string element, vector color)
{
    integer i=llListFindList(colorsettings,[element]);
    if ((i==-1)||(llList2Vector(colorsettings,i+1)!=color))
    {
        integer n;
        integer linkcount = llGetNumberOfPrims();
        for (n = 2; n <= linkcount; n++)
        {
            string thiselement = ElementColorType(n);
            if (thiselement == element)
                llSetLinkColor(n, color, ALL_SIDES);//set link to new color
        }
        //change the colorsettings list entry for the current element
        integer index = llListFindList(colorsettings, [element]);
        if (index == -1)
            colorsettings += [element, color];
        else
            colorsettings = llListReplaceList(colorsettings, [color], index + 1, index + 1);
    }
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
    else
        LM_CUFF_CMD(szMsg, keyID);
}

LM_CUFF_CMD(string szMsg, key id)
{// message for cuff received;
    // or info about RLV to be used
    if (nStartsWith(szMsg,g_szLockCmd))
    {// it is a lock commans
        list lstCmdList    = llParseString2List( szMsg, [ "=" ], [] );
        if (llList2String(lstCmdList,1)=="on")
            g_nLocked=TRUE;
        else
            g_nLocked=FALSE;
        // Update Cuff lock status
        SetLocking();
    }
    else if (szMsg == "rlvon")
    {// RLV got activated
        g_nUseRLV=TRUE;
        SetLocking();// Update Cuff lock status
    }
    else if (szMsg == "rlvoff")
    {// RLV got deactivated
        g_nUseRLV=FALSE;
        SetLocking();// Update Cuff lock status
    }
    //apperance
    else if (nStartsWith(szMsg,g_szColorChangeCmd))
    { // a change of colors has occured, make sure the cuff try to set identiccal to the collar
        list lstCmdList    = llParseString2List( szMsg, [ "=" ], [] );
        // set the color, uses StripSpace fix for colrs just in case
        SetElementColor(llList2String(lstCmdList,1),(vector)szStripSpaces(llList2String(lstCmdList,2)));   
    }
    else if (nStartsWith(szMsg,g_szTextureChangeCmd))
    { // a change of colors has occured, make sure the cuff try to set identiccal to the collar
        list lstCmdList    = llParseString2List( szMsg, [ "=" ], [] );
        // set the texture
        SetElementTexture(llList2String(lstCmdList,1),szStripSpaces(llList2String(lstCmdList,2)));   
    }
    else if (nStartsWith(szMsg,g_szHideCmd))
    { // a change of colors has occured, make sure the cuff try to set identiccal to the collar
        list lstCmdList    = llParseString2List( szMsg, [ "=" ], [] );
        g_nHidden= llList2Integer(lstCmdList,1);
        if (g_nHidden)
            SetAllElementsAlpha (0.0);
        else
            SetAllElementsAlpha (1.0);
    }
}

SetAllElementsAlpha(float fAlpha)
{//loop through links, setting color if element type matches what we're changing
    //root prim is 1, so start at 2
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    string sAlpha = Float2String((string)fAlpha);
    for (n = 2; n <= iLinkCount; n++)
    {
        string sElement = ElementType(n);
        llSetLinkAlpha(n, fAlpha, ALL_SIDES);
        //update element in list of settings
        integer iIndex = llListFindList(g_lAlphaSettings, [sElement]);
        if (iIndex == -1)
            g_lAlphaSettings += [sElement, sAlpha];
        else
            g_lAlphaSettings = llListReplaceList(g_lAlphaSettings, [sAlpha], iIndex + 1, iIndex + 1);
    }
}

string Float2String(string out)
{
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0")
        out = llGetSubString(out, 0, -2);
    return out;
}

string ElementType(integer linkiNumber)
{
    string sDesc = (string)llGetObjectDetails(llGetLinkKey(linkiNumber), [OBJECT_DESC]);
    //each prim should have <elementname> in its description, plus "nocolor" or "notexture", if you want the prim to  not appear in the color or texture menus
    list lParams = llParseString2List(sDesc, ["~"], []);
    if ((~(integer)llListFindList(lParams, [g_sIgnore])) || sDesc == "" || sDesc == " " || sDesc == "(No Description)")
        return g_sIgnore;
    else
        return llList2String(lParams, 0);
}

Init()
{
    if (scanLinkset()){ } // resizer script ready;
    g_keyWearer = llGetOwner();
    // get unique channel numbers for the command and cuff channel, cuff channel wil be used for LG chains of cuffs as well
    g_nCmdChannel = nGetOwnerChannel(g_nCmdChannelOffset);
    g_nInternalLockGuardChannel=g_nCmdChannel+1;
    llListenRemove(g_nCmdHandle);
    g_nCmdHandle = llListen(g_nInternalLockGuardChannel, "", NULL_KEY, "");
    g_lstModTokens = (list)llList2String(lstCuffNames,llGetAttached()); // get name of the cuff from the attachment point, this is absolutly needed for the system to work, other chain point wil be received via LMs

    g_szModToken=llList2String(lstCuffNames,llGetAttached());
    BuildTextureList(); //build list of parts we can texture
    BuildColorElementList(); //built list of parts we can color
    // listen to LockGuard requests
    llListen(g_nLockGuardChannel,"","",""); 
    llWhisper(g_nCmdChannel, g_szModToken + "|rlac|" + g_szInfoRequest + "|" + (string)g_keyWearer);// request infos from main cuff
    SetLocking(); // and set all existing lockstates now
    //resize
    llListenRemove(handle);
    menuChan = 50000 + (integer)llFrand(50000.00);
    handle = llListen(menuChan,"",llGetOwner(),"");
    
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
}

default
{
    state_entry()
    {
        Init(); 
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
        {
            Init();// we keep loosing who we are so main cuff won't hear us
            if (g_nLockedState)
                llOwnerSay("@detach=n");
        }
        else
            llResetScript();
    }

    touch_start(integer nCnt)
    {
        key id = llDetectedKey(0);
        if ((llGetAttached() == 0)&& (id==g_keyWearer)) // If not attached then wake up update script then do nothing
        {
            llSetScriptState("OpenNC - update",TRUE);
            return;
        }
        else if (llDetectedKey(0) == llGetOwner())// if we are wearer then allow to resize
        {
            if(show_size == TRUE)
                llDialog(llGetOwner(),"Select if you want to Resize this item or the main Cuff Menu ",["Resizer","Cuff Menu", "Remove Resizer"],menuChan);
            else
                SendCmd("rlac", "cmenu=on="+(string)id);
        }
        // else just ask for main cuff menu
        else
            SendCmd("rlac", "cmenu=on="+(string)id);
    }

    listen(integer nChannel, string szName, key keyID, string szMsg)
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
        else if (keyID == llGetOwner())
        {
            if (szMsg == "Cuff Menu")
                SendCmd("rlac", "cmenu=on="+(string)keyID);
            else if (szMsg == "Remove Resizer")
                show_size = FALSE;
            else if (szMsg == "Resizer")
                makeMenu();
            else
            {
                if (szMsg == "RESTORE")
                    cur_scale = 1.0;
                else if (szMsg == "MIN SIZE")
                    cur_scale = min_scale;
                else if (szMsg == "MAX SIZE")
                    cur_scale = max_scale;
                else
                    cur_scale += (float)szMsg;
                //check that the scale doesn't go beyond the bounds
                if (cur_scale > max_scale)
                    cur_scale = max_scale;
                if (cur_scale < min_scale)
                    cur_scale = min_scale;
                resizeObject(cur_scale);
                makeMenu();
            }
        }
    }
}