{-# LANGUAGE OverloadedStrings, FlexibleContexts, GADTs, ScopedTypeVariables #-}

{-|
Description: The main graph module. __Start here__.

This module is reponsible for parsing the SVG files exported from Inkscape.
It also currently acts as a main driver for the whole graph pipeline:

1. Parsing the raw SVG files
2. Inserting them into the database (see "Svg.Database")
3. Retrieving the database values and generating a new SVG file
   (See "Svg.Builder" and "Svg.Generator")

The final svg files are output in @public\/res\/graphs\/gen@ and are sent
directly to the client when viewing the @/graph@ page.
-}

module Svg.Parser
    (parsePrebuiltSvgs) where

import Data.Maybe (mapMaybe, fromMaybe, fromJust, isNothing)
import Data.List.Split (splitOn)
import Data.List (find)
import qualified Data.Map as M (empty)
import Data.String.Utils (replace)
import Text.XML.HaXml hiding (find, qname, x, attr)
import Text.XML.HaXml.Util (tagTextContent)
import Text.XML.HaXml.Namespaces (printableName)
import System.Directory
import Database.Tables
import Database.DataType
import Svg.Database (insertGraph, insertElements, deleteGraphs)
import Svg.Generator
import Database.Persist.Sqlite hiding (replace)
import Config (graphPath)
import Text.Read (readMaybe, readEither)

parsePrebuiltSvgs :: IO ()
parsePrebuiltSvgs = do
    deleteGraphs
    performParse "Computer Science" "csc2016.svg"
    performParse "Statistics" "sta2015.svg"
    performParse "Biochemistry" "bch2015.svg"
    performParse "Cell & Systems Biology" "csb2015.svg"
    performParse "Estonian" "est2015.svg"
    performParse "Finnish" "fin2015.svg"
    performParse "Italian" "ita2015.svg"
    performParse "Linguistics" "lin2015.svg"
    performParse "Rotman" "rotman2015.svg"
    performParse "Economics" "eco2015.svg"
    performParse "Spanish" "spa2015.svg"
    performParse "Portuguese" "prt2015.svg"
    performParse "Slavic"  "sla2015.svg"
    performParse "East Asian Studies" "eas2015.svg"
    performParse "English" "eng2015.svg"
    performParse "History and Philosophy of Science" "hps2015.svg"
    performParse "History" "his2015.svg"
    performParse "Geography" "ggr2015.svg"
    performParse "Aboriginal" "abs2015.svg"

performParse :: String -- ^ The title of the graph.
             -> String -- ^ The filename of the file that will be parsed.
             -> IO ()
performParse graphName inputFilename = do
    graphFile <- readFile (graphPath ++ inputFilename)
    let (graphWidth, graphHeight) = parseSize graphFile
    key <- insertGraph graphName graphWidth graphHeight
    let parsedGraph = parseGraph key graphFile
        PersistInt64 keyVal = toPersistValue key
    print "Graph Parsed"
    insertElements parsedGraph
    print "Graph Inserted"
    let genGraphPath = graphPath ++ "gen/"
    createDirectoryIfMissing True genGraphPath
    buildSVG key M.empty (genGraphPath ++ show keyVal ++ ".svg") False
    print "Success"


-- * Parsing functions

-- | Parses an SVG file.
--
-- This and the following functions traverse the raw SVG tree and return
-- three lists, each containing values corresponding to different graph elements
-- (edges, nodes, and text).
parseGraph ::  GraphId  -- ^ The unique identifier of the graph.
            -> String   -- ^ The file contents of the graph that will be parsed.
            -> ([Path],[Shape],[Text])
parseGraph key graphFile =
    let Document _ _ root _ = xmlParse "output.error" graphFile
        svgElems = tag "svg" $ CElem root undefined
        svgRoot = head svgElems
        (paths, shapes, texts) = parseNode key svgRoot
        shapes' = removeRedundant shapes
    in
        if null svgElems
        then
            error "No svg element detected"
        else
            (paths, filter small shapes', texts)
    where
        -- Raw SVG seems to have a rectangle the size of the whole image
        small shape = shapeWidth shape < 300
        removeRedundant shapes =
            filter (not . \s -> (elem (shapePos s) (map shapePos shapes)) &&
                                (null (shapeFill s) || shapeFill s == "#000000") &&
                                elem (shapeType_ s) [Node, Hybrid]) shapes

-- | Parse the height and width dimensions from the SVG element, respectively,
-- and return them as a tuple.
parseSize :: String   -- ^ The file contents of the graph that will be parsed.
          -> (Double, Double)
parseSize graphFile =
    let Document _ _ root _ = xmlParse "output.error" graphFile
        svgElems = tag "svg" $ CElem root undefined
        svgRoot = head svgElems
        attrs = contentAttrs svgRoot
        width = readAttr "width" attrs
        height = readAttr "height" attrs
    in
        if null svgElems
        then
            error "No svg element detected"
        else
            (width, height)

-- | The main parsing function. Parses an SVG element,
-- and then recurses on its children.
parseNode :: GraphId  -- ^ The Path's corresponding graph identifier.
          -> Content i
          -> ([Path],[Shape],[Text])
parseNode key content =
    if getName content == "defs"
    then ([],[],[])
    else let attrs = contentAttrs content
             trans = parseTransform $ lookupAttr "transform" attrs
             styles' = styles (contentAttrs content)
             fill = styleVal "fill" styles'
             -- TODO: These 'tag "_"' conditions are mutually exclusive (I think).
             rects = map (parseRect key . contentAttrs) (tag "rect" content)
             texts = concatMap (parseText key styles' []) (tag "text" content)
             paths = mapMaybe (parsePath key . contentAttrs) (tag "path" content)
             ellipses = map (parseEllipse key . contentAttrs) (tag "ellipse" content)
             concatThree (a1, b1, c1) (a2, b2, c2) =
                 (a1 ++ a2, b1 ++ b2, c1 ++ c2)
             (newPaths, newShapes, newTexts) =
                foldl concatThree (paths, rects ++ ellipses, texts)
                                  (map (parseNode key) (path [children] content))
         in
             (map (updatePath fill trans) newPaths,
              map (updateShape fill trans) newShapes,
              map (updateText trans) newTexts)

-- | Create a rectangle from a list of attributes.
parseRect :: GraphId -- ^ The Rect's corresponding graph identifier.
          -> [Attribute]
          -> Shape
parseRect key attrs =
    Shape key
          ""
          (readAttr "x" attrs,
           readAttr "y" attrs)
          (readAttr "width" attrs)
          (readAttr "height" attrs)
          (styleVal "fill" (styles attrs))
          ""
          []
          9
          Node

-- | Create an ellipse from a list of attributes.
parseEllipse :: GraphId -- ^ The Ellipse's corresponding graph identifier.
             -> [Attribute]
             -> Shape
parseEllipse key attrs =
    Shape key
          ""
          (readAttr "cx" attrs,
           readAttr "cy" attrs)
          (readAttr "rx" attrs * 2)
          (readAttr "ry" attrs * 2)
          ""
          ""
          []
          20
          BoolNode

-- | Create a path from a list of attributes.
parsePath :: GraphId -- ^ The Path's corresponding graph identifier.
          -> [Attribute]
          -> Maybe Path
parsePath key attrs =
    if last (lookupAttr "d" attrs) == 'z' && not isRegion
    then Nothing
    else Just (Path key
                    ""
                    d
                    ""
                    ""
                    isRegion
                    ""
                    "")
    where
        d = parsePathD $ lookupAttr "d" attrs
        fillAttr = styleVal "fill" (styles attrs)
        isRegion = not $
            null fillAttr || fillAttr == "none"

-- | Create text values from content.
-- It is necessary to pass in the content because we need to search
-- for nested tspan elements.
parseText :: GraphId -- ^ The Text's corresponding graph identifier.
          -> [(String, String)]
          -> [Attribute]  -- ^ Ancestor tspan attributes
          -> Content i
          -> [Text]
parseText key style parentAttrs content =
    if null (childrenBy (tag "tspan") content)
    then
        [Text key
              (lookupAttr "id" (contentAttrs content ++ parentAttrs))
              (readAttr "x" (contentAttrs content ++ parentAttrs),
               readAttr "y" (contentAttrs content ++ parentAttrs))
              (replace "&amp;" "&" (replace "&gt;" ">" $ tagTextContent content))
              align
              fill]
    else
        concatMap (parseText key (styles $ contentAttrs content)
                             (contentAttrs content ++ parentAttrs))
                  (childrenBy (tag "tspan") content)
    where
        newStyle = style ++ styles (contentAttrs content)
        alignAttr = styleVal "text-anchor" newStyle
        align = if null alignAttr
                then "begin"
                else alignAttr
        fill = styleVal "fill" newStyle


-- * Helpers for manipulating attributes

-- | Gets the tag name of a Content Element.
getName :: Content i -> String
getName (CElem (Elem a _ _) _) = printableName a
getName _ = ""

contentAttrs :: Content i -> [Attribute]
contentAttrs (CElem (Elem _ attrs _) _) = attrs
contentAttrs _ = []

-- | Gets an Attribute's name.
attrName :: Attribute -> String
attrName (qname, _) = printableName qname

-- | Looks up the (string) value of the attribute with the corresponding name.
-- Returns the empty string if the attribute isn't found.
lookupAttr :: String -> [Attribute] -> String
lookupAttr nameStr attrs =
    maybe "" (show . snd) $ find (\x -> attrName x == nameStr) attrs

-- | Looks up an attribute value and convert to another type.
readAttr :: Read a => String    -- ^ The attribute's name.
                   -> [Attribute] -- ^ The element that contains the attribute.
                   -> a
readAttr attr attrs =
    case readMaybe $ lookupAttr attr attrs of
        Just x -> x
        Nothing -> error $ "reading " ++ attr ++ " from " ++ show attrs

-- | Return a list of styles from the style attribute of an element.
-- Every style has the form (name, value).
styles :: [Attribute] -> [(String, String)]
styles attrs =
    let styleStr = lookupAttr "style" attrs
    in map toStyle $ splitOn ";" styleStr
    where
        toStyle split =
            case splitOn ":" split of
            [n,v] -> (n,v)
            _ -> ("","")

-- | Gets a style attribute from a style string.
styleVal :: String -> [(String, String)] -> String
styleVal nameStr styleMap = fromMaybe "" $ lookup nameStr styleMap

-- | Parses a transform String into a tuple of Float.
parseTransform :: String -> Point
parseTransform "" = (0,0)
parseTransform transform =
    let parsedTransform = splitOn "," $ drop 10 transform
        xPos = readMaybe $ parsedTransform !! 0
        yPos = readMaybe $ init $ parsedTransform !! 1
    in
        if isNothing xPos || isNothing yPos
        then
            error transform
        else
            (fromJust xPos, fromJust yPos)

-- | Parses a path's `d` attribute.
parsePathD :: String -- ^ The 'd' attribute of an SVG path.
           -> [Point]
parsePathD d
    | head d == 'm' = relCoords
    | otherwise = absCoords
    where
      lengthMoreThanOne x = length x > 1
      coordList = filter lengthMoreThanOne (map (splitOn ",") $ splitOn " " d)
      -- Converts a relative coordinate structure into an absolute one.
      relCoords = tail $ foldl (\x z -> x ++ [addTuples (convertToPoint z)
                                                        (last x)])
                               [(0,0)]
                               coordList
      -- Converts a relative coordinate structure into an absolute one.
      absCoords = map convertToPoint coordList

      convertToPoint z =
        let
            x = readMaybe (head z)
            y = readMaybe (last z)
        in
            case (x, y) of
                (Just m, Just n) -> (m, n)
                _ -> error $ show z


-- * Other helpers

-- | These functions are used to update the parsed values
-- with styles (transform and fill) inherited from their parents.
--
-- Eventually, it would be nice if we removed these functions and
-- simply passed everything down when making the recursive calls.

updatePath :: String -- ^ The fill that may be added to the Path.
           -> Point  -- ^ Transform that will be added to the Shape's
                     --   current transform value.
           -> Path
           -> Path
updatePath fill transform p =
    p { pathPoints = map (addTuples transform) (pathPoints p),
        pathFill = if null (pathFill p) then fill else pathFill p
      }

updateShape :: String -- ^ The fill that may be added to the Shape.
            -> Point  -- ^ Transform that will be added to the Shape's
                      --   current transform value.
            -> Shape
            -> Shape
updateShape fill transform r =
    r { shapePos = addTuples transform (shapePos r),
        shapeFill = if null (shapeFill r) || shapeFill r == "none"
                    then fill
                    else shapeFill r,
        shapeType_ = if fill == "#888888" then Hybrid
                     else case shapeType_ r of
                              Hybrid   -> Hybrid
                              BoolNode -> BoolNode
                              Node     -> Node
      }

updateText :: Point -- ^ Transform that will be added to the input Shape's
                    -- current transform value.
           -> Text
           -> Text
updateText transform t =
    t { textPos = addTuples transform (textPos t) }

-- | Adds two tuples together.
addTuples :: Point -> Point -> Point
addTuples (a,b) (c,d) = (a + c, b + d)