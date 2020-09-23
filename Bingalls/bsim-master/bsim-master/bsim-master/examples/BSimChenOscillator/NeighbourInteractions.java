package BSimChenOscillator;

import bsim.BSim;
import bsim.BSimChemicalField;
import bsim.BSimTicker;
import bsim.BSimUtils;
import bsim.capsule.BSimCapsuleBacterium;
import bsim.capsule.Mover;
import bsim.capsule.RelaxationMoverGrid;
import bsim.draw.BSimDrawer;
import bsim.draw.BSimP3DDrawer;
import bsim.export.BSimLogger;
import bsim.export.BSimPngExporter;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import processing.core.PConstants;
import processing.core.PGraphics3D;

import javax.vecmath.*;
import java.awt.*;
import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.util.*;
import java.util.List;
import java.lang.Math;
import java.util.Arrays;

/**
 * Chen oscillator in microfluidic chamber with fixed (non-growing) population.
 *
 * We adjust the diffusion, the boundary conditions, the density of cells, and the ratio of activators vs repressors.
 */
public class NeighbourInteractions {

    @Parameter(names = "-export", description = "Enable export mode.")
    private boolean export = true;

    @Parameter(names = "-dim", arity = 3, description = "The dimensions (x, y, z) of simulation environment (um).")
    public List<Double> simDimensions = new ArrayList<>(Arrays.asList(new Double[] {275.20, 220.80, 1.}));

    // Diffusion
    @Parameter(names = "-diff", arity = 1, description = "External diffusivity.")
    public double diffusivity = 5.0;

    // External degradation
    @Parameter(names = "-mu_e", arity = 1, description = "External degradation.")
    public double mu_e = 0.1;

    // Boundaries
    @Parameter(names = "-fixedbounds", description = "Enable fixed boundaries. (If not, one boundary will be leaky as real uf chamber).")
    private boolean fixedBounds = false;

    // Grid ->
    // 52x42 -> 546
    // 100x86 -> 2150
    // Random:
    // 50x42 -> 250
    // 100x85 -> 1000
    // Density (cell number)
    @Parameter(names = "-pop", arity = 1, description = "Initial seed population (n_total).")
    public int initialPopulation = 10;

    // A:R ratio
    @Parameter(names = "-ratio", arity = 1, description = "Ratio of initial populations (proportion of activators).")
    public double populationRatio = 0.0;

    // Multipliers for the cell wall diffusion, and for the synthesis of QS molecules.
    @Parameter(names = "-qspars", arity = 4, description = "Multipliers for the quorum sensing parameters. [D_H, D_I, phi_H, phi_I].")
    public List<Double> qsPars = new ArrayList<>(Arrays.asList(new Double[] {0., 2.1, 0., 10.}));


    /**
     * Whether to enable growth in the ticker etc. or not...
     */
    private static final boolean WITH_GROWTH = true;


    public static void main(String[] args) {
        NeighbourInteractions bsim_ex = new NeighbourInteractions();

        new JCommander(bsim_ex, args);

        bsim_ex.run();
    }

    public void run() {
        /*********************************************************
         * Initialise parameters from command line
         */
        final double simX = simDimensions.get(0);
        final double simY = simDimensions.get(1);
        final double simZ = simDimensions.get(2);

        int nActivatorStart = (int)Math.round(populationRatio*initialPopulation);
        int nRepressorStart = (int)Math.round((1 - populationRatio)*initialPopulation);

        long simulationStartTime = System.nanoTime();

        // create the simulation object
        final BSim sim = new BSim();
        sim.setDt(0.01);				    // Simulation Timestep
        sim.setSimulationTime(80);       // 36000 = 10 hours; 600 minutes.
//        sim.setSimulationTime(60000);
        sim.setTimeFormat("0.00");		    // Time Format for display
        sim.setBound(simX, simY, simZ);		// Simulation Boundaries

        /**
         * OK, so we need to set up the global parameters from inputs.
         * Would it be good to do this from a file?
         */
        double def_D_H = ChenParameters.p.get("D_H");
        ChenParameters.p.put("D_H", def_D_H*qsPars.get(0));
        double def_D_I = ChenParameters.p.get("D_I");
        ChenParameters.p.put("D_I", def_D_I*qsPars.get(1));

        double def_phi_H = ChenParameters.p.get("phi_H");
        ChenParameters.p.put("phi_H", def_phi_H*qsPars.get(2));
        double def_phi_I = ChenParameters.p.get("phi_I");
        ChenParameters.p.put("phi_I", def_phi_I*qsPars.get(3));


        /*********************************************************
         * Set up the chemical fields
         */
        double external_diffusivity = diffusivity/60.0;
        // 800/60 - repressor oscillates but activator levels out rapidly
        // 80/60 - more transients, only starts levelling at the end of the 10 hours

        // Boundaries are not periodic
        sim.setSolid(true, true, true);

        // Leaky on the bottom
        if(!fixedBounds) {
            sim.setLeaky(true, true, true, true,false, false);
            sim.setLeakyRate(0.1/60.0, 0.1/60.0, 0.1/60.0, 0.1/60.0, 0, 0);
        }

        double external_decay = mu_e/60.0;

        final BSimChemicalField h_e_field = new BSimChemicalField(sim, new int[] {(int) simX, (int)simY, 1}, external_diffusivity, external_decay);
        final BSimChemicalField i_e_field = new BSimChemicalField(sim, new int[] {(int) simX, (int)simY, 1}, external_diffusivity, external_decay);

        // ICs as in Chen paper (as in original DDEs)
        h_e_field.setConc(0);
        i_e_field.setConc(0);

        /*********************************************************
         * Create the bacteria
         */
        // Separate lists of bacteria in case we want to manipulate the species individually
        final ArrayList<ChenBacterium> bac0 = new ArrayList();
        final ArrayList<ChenBacterium> bac1 = new ArrayList();

        //


        // Track all of the bacteria in the simulation, for use of common methods etc
        final ArrayList<BSimCapsuleBacterium> bacteriaAll = new ArrayList();

        double[][] initEndpoints = new double[4][];

        BufferedReader csvReader = null;
        try {
            csvReader = new BufferedReader(new FileReader("C:\\Users\\catie\\Documents\\code\\Bingalls\\bsim-master\\bsim-master\\bsim-master\\examples\\BSimChenOscillator\\initialpositions2.csv"));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
        try {
            String row = csvReader.readLine();
            int i=0;
            while (row != null) {
                initEndpoints[i] = Arrays.stream(row.split(",")).mapToDouble(Double::parseDouble).toArray();
                row = csvReader.readLine();
                i=i+1;
            }
            csvReader.close();
        } catch(IOException e) {
            e.printStackTrace();
        }
        Random bacRng = new Random();
        bacRng.setSeed(50);
        for(int j=0;j<initEndpoints[0].length;j++){
            Vector3d x1 = new Vector3d(initEndpoints[0][j]/10,initEndpoints[1][j]/10,bacRng.nextDouble()*0.1*(simZ - 0.1)/2.0);
            Vector3d x2 = new Vector3d(initEndpoints[2][j]/10,initEndpoints[3][j]/10,bacRng.nextDouble()*0.1*(simZ - 0.1)/2.0);
            ChenBacterium bac = new ChenBacterium(sim,x1,x2,i_e_field,false);
            bac0.add(bac);
            bacteriaAll.add(bac);
        }

//        PopulationGenerator popGen = new PopulationGenerator(sim, bacteriaAll, bacteriaActivators, bacteriaRepressors, h_e_field, i_e_field);
//
//        popGen.mixedAsBlock(nActivatorStart, nRepressorStart);

//        Random bacRng = new Random();
//        bacRng.setSeed(50);

//        generator:
//        while(bac0.size() < nActivatorStart) {
//            double bL = 1. + 0.1*(bacRng.nextDouble() - 0.5);
//            double angle = bacRng.nextDouble()*2*Math.PI;
//
//            Vector3d pos = new Vector3d(1.1 + bacRng.nextDouble()*(sim.getBound().x - 2.2), 1.1 + bacRng.nextDouble()*(sim.getBound().y - 2.2), bacRng.nextDouble()*0.1*(simZ - 0.1)/2.0);
//            // Test intersection
//
//            Vector3d distance = new Vector3d(0,0,0);
//
//            for(BSimCapsuleBacterium otherBac : bacteriaAll){
//                distance.sub(otherBac.position, pos);
//                if(distance.lengthSquared() < 4.5){
//                    continue generator;
//                }
//            }
//
//            ChenBacterium bac = new ChenBacterium(sim,
//                    new Vector3d(pos.x - bL*Math.sin(angle), pos.y - bL*Math.cos(angle), pos.z),
//                    new Vector3d(bL*Math.sin(angle) + pos.x, bL*Math.cos(angle) + pos.y, pos.z), i_e_field, 3<2);
//
//            bac.L = bL;
//
//            bac0.add(bac);
//            bacteriaAll.add(bac);
//        }

//        generator:
//        while(bac1.size() < nRepressorStart) {
//            double bL = 1. + 0.1*(bacRng.nextDouble() - 0.5);
//            double angle = bacRng.nextDouble()*2*Math.PI;
//
//            Vector3d pos = new Vector3d(1.1 + bacRng.nextDouble()*(sim.getBound().x - 2.2), 1.1 + bacRng.nextDouble()*(sim.getBound().y - 2.2), simZ/2.0);
//            // Test intersection
//
//            Vector3d distance = new Vector3d(0,0,0);
//
//            for(BSimCapsuleBacterium otherBac : bacteriaAll){
//                distance.sub(otherBac.position, pos);
//                if(distance.lengthSquared() < 4.5){
//                    continue generator;
//                }
//            }
//
//            ChenBacterium bac = new ChenBacterium (sim,
//                    new Vector3d(pos.x - bL*Math.sin(angle), pos.y - bL*Math.cos(angle), pos.z),
//                    new Vector3d(bL*Math.sin(angle) + pos.x, bL*Math.cos(angle) + pos.y, pos.z),
//                    i_e_field, 3>2);
//
//            bac.L = bL;
//
//            bac1.add(bac);
//            bacteriaAll.add(bac);
//        }

        // Set up stuff for growth.
        final ArrayList<ChenBacterium> bac0_born = new ArrayList();
        final ArrayList<ChenBacterium> bac0_dead = new ArrayList();

        final ArrayList<ChenBacterium> bac1_born = new ArrayList();
        final ArrayList<ChenBacterium> bac1_dead = new ArrayList();

        final ArrayList<ChenBacterium> bac0_switch = new ArrayList();
        final ArrayList<ChenBacterium> bac1_switch =new ArrayList();


        final Mover mover;


        mover = new RelaxationMoverGrid(bacteriaAll, sim);



        /*********************************************************
         * Set up the ticker
         */
        final int LOG_INTERVAL = 100;

        BSimTicker ticker = new BSimTicker() {
            @Override
            public void tick() {
                // ********************************************** Action
                long startTimeAction = System.nanoTime();

                for(BSimCapsuleBacterium b : bacteriaAll) {
                    b.action();
                }

                long endTimeAction = System.nanoTime();
                if((sim.getTimestep() % LOG_INTERVAL) == 0) {
                    System.out.println("Action update for " + bacteriaAll.size() + " bacteria took " + (endTimeAction - startTimeAction)/1e6 + " ms.");
                }

                // ********************************************** Chemical fields
                startTimeAction = System.nanoTime();

                h_e_field.update();
                i_e_field.update();

                endTimeAction = System.nanoTime();
                if((sim.getTimestep() % LOG_INTERVAL) == 0) {
                    System.out.println("Chemical field update took " + (endTimeAction - startTimeAction)/1e6 + " ms.");
                }

                // ********************************************** Growth related activities if enabled.
                if(WITH_GROWTH) {

                    // ********************************************** Growth and division
                    startTimeAction = System.nanoTime();

                    for (ChenBacterium b : bac0) {
                        // activators are inhibited by density of inhibitor concentration
                        b.setK_growth(0.2-0.2/255*i_e_field.getConc(b.position));
                        if(i_e_field.getConc(b.position)>255)
                            b.setK_growth(0.);
                            b.grow();

                        // Divide if grown past threshold
                        if (b.L > b.L_th) {
                            bac0_born.add(b.divide(false));
                        }
                    }
                    bac0.addAll(bac0_born);
                    bacteriaAll.addAll(bac0_born);
                    bac0_born.clear();

                    for (ChenBacterium b : bac1) {
                        b.grow();

                        // Divide if grown past threshold
                        if (b.L > b.L_th) {
                            bac1_born.add(b.divide(true));
                        }
                    }
                    bac1.addAll(bac1_born);
                    bacteriaAll.addAll(bac1_born);
                    bac1_born.clear();

                    endTimeAction = System.nanoTime();
                    if ((sim.getTimestep() % LOG_INTERVAL) == 0) {
                        System.out.println("Growth and division took " + (endTimeAction - startTimeAction) / 1e6 + " ms.");
                    }

                    // ********************************************** Neighbour interactions
                    startTimeAction = System.nanoTime();

                    mover.move();

                    endTimeAction = System.nanoTime();
                    if ((sim.getTimestep() % LOG_INTERVAL) == 0) {
                        System.out.println("Wall and neighbour interactions took " + (endTimeAction - startTimeAction) / 1e6 + " ms.");
                    }

                    // ********************************************** Boundaries/removal
                    startTimeAction = System.nanoTime();
                    // Removal
                    for (ChenBacterium b : bac0) {
//                         Kick out if past the top or bottom boundaries
//                        if ((b.x1.y < 0) && (b.x2.y < 0)) {
//                            act_dead.add(b);
//                        }
//                        if ((b.x1.y > sim.getBound().y) && (b.x2.y > sim.getBound().y)) {
//                            act_dead.add(b);
//                        }
                        // kick out if past any boundary
                        if(b.position.x < 0 || b.position.x > sim.getBound().x || b.position.y < 0 || b.position.y > sim.getBound().y || b.position.z < 0 || b.position.z > sim.getBound().z){
                            bac0_dead.add(b);
                        }
                    }
                    bac0.removeAll(bac0_dead);
                    bacteriaAll.removeAll(bac0_dead);
                    bac0_dead.clear();

                    // Removal
                    for (ChenBacterium b : bac1) {
                        // Kick out if past the boundary
//                        if ((b.x1.y < 0) && (b.x2.y < 0)) {
//                            rep_dead.add(b);
//                        }
//                        if ((b.x1.y > sim.getBound().y) && (b.x2.y > sim.getBound().y)) {
//                            rep_dead.add(b);
//                        }
                        if(b.position.x < 0 || b.position.x > sim.getBound().x || b.position.y < 0 || b.position.y > sim.getBound().y || b.position.z < 0 || b.position.z > sim.getBound().z){
                            bac1_dead.add(b);
                        }
                    }
                    bac1.removeAll(bac1_dead);
                    bacteriaAll.removeAll(bac1_dead);
                    bac1_dead.clear();



                    endTimeAction = System.nanoTime();
                    if ((sim.getTimestep() % LOG_INTERVAL) == 0) {
                        System.out.println("Death and removal took " + (endTimeAction - startTimeAction) / 1e6 + " ms.");
                    }
                }
                //switch activator to repressor

                startTimeAction = System.nanoTime(); //what is the difference between activator/repressor and infected/noninfected

                for (ChenBacterium b : bac0) {
                    double n= Math.random()*510;
                    System.out.println(n);

                    if(n<=i_e_field.getConc(b.position)){
                        b.set_count(b.get_count()+1);
                        if(b.get_count()>50){
                            bac0_switch.add(b);
                            ChenBacterium newbac = new ChenBacterium(sim, b.x1, b.x2,
                                    b.I_e_field, true);
                            bac1_switch.add(newbac);}
                    }
                }
                bac0.removeAll(bac0_switch);
                bacteriaAll.removeAll(bac0_switch);
                bac1.addAll(bac1_switch);
                bacteriaAll.addAll(bac1_switch);
                bac0_switch.clear();
                bac1_switch.clear();

                endTimeAction = System.nanoTime();
                if ((sim.getTimestep() % LOG_INTERVAL) == 0) {
                    System.out.println("Switch took " + (endTimeAction - startTimeAction) / 1e6 + " ms.");
                }

            }
        };

        sim.setTicker(ticker);

        


        /*********************************************************
         * Set up the drawer
         */
        BSimDrawer drawer = new BSimP3DDrawer(sim, 800, 600) {
            /**
             * Draw the default cuboid boundary of the simulation as a partially transparent box
             * with a wireframe outline surrounding it.
             */
            @Override
            public void boundaries() {
                p3d.noFill();
                p3d.stroke(128, 128, 255);
                p3d.pushMatrix();
                p3d.translate((float)boundCentre.x,(float)boundCentre.y,(float)boundCentre.z);
                p3d.box((float)bound.x, (float)bound.y, (float)bound.z);
                p3d.popMatrix();
                p3d.noStroke();
            }

            @Override
            public void draw(Graphics2D g) {
                p3d.beginDraw();

                if(!cameraIsInitialised){
                    // camera(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ)
                    p3d.camera((float)bound.x*0.5f, (float)bound.y*0.5f,
                            // Set the Z offset to the largest of X/Y dimensions for a reasonable zoom-out distance:
                            simX > simY ? (float)simX : (float)simY,
//                            10,
                            (float)bound.x*0.5f, (float)bound.y*0.5f, 0,
                            0,1,0);
                    cameraIsInitialised = true;
                }

                p3d.textFont(font);
                p3d.textMode(PConstants.SCREEN);

                p3d.sphereDetail(10);
                p3d.noStroke();
                p3d.background(255, 255,255);

                scene(p3d);
                boundaries();
                time();

                p3d.endDraw();
                g.drawImage(p3d.image, 0,0, null);
            }

            /**
             * Draw the formatted simulation time to screen.
             */
            @Override
            public void time() {
                p3d.fill(0);
//                p3d.text(sim.getFormattedTimeHours(), 50, 50);
                p3d.text(sim.getFormattedTime(), 50, 50);
            }

            @Override
            public void scene(PGraphics3D p3d) {
                p3d.ambientLight(128, 128, 128);
                p3d.directionalLight(128, 128, 128, 1, 1, -1);

//                draw(bac_act, new Color(55, 126, 184));
//                draw(bac_rep, new Color(228, 26, 28));

                for(ChenBacterium b : bac0) {
                    draw(b, Color.blue);
                }

                for(ChenBacterium b : bac1) {
                    draw(b, Color.green);
                }

                draw(i_e_field, Color.red, (float)(1.0));
            }
        };
        sim.setDrawer(drawer);




        export=true;
        if(export) {
            String simParameters = "" + BSimUtils.timeStamp() + "__dim_" + simX + "_" + simY + "_" + simZ
                    + "__ip_" + initialPopulation
                    + "__pr_" + populationRatio
                    + "__diff_" + diffusivity
                    + "__deg_" + mu_e
                    + "__qs_" + qsPars.get(0) + "_" + qsPars.get(1) + "_" + qsPars.get(2) + "_" + qsPars.get(3);

            if(fixedBounds){
                simParameters += "__fixedBounds";
            } else {
                simParameters += "__leakyBounds";
            }

            String filePath = BSimUtils.generateDirectoryPath("/home/caterrey/BSim2/out/production/" + simParameters + "/");
//            String filePath = BSimUtils.generateDirectoryPath("/home/am6465/tmp-results/" + simParameters + "/");


            /*********************************************************
             * Various properties of the simulation, for future reference.
             */
            BSimLogger metaLogger = new BSimLogger(sim, filePath + "simInfo.txt") {
                @Override
                public void before() {
                    super.before();
                    write("Simulation metadata.");
                    write("Chen/Bennett consortium oscillator system.");
                    write("Simulation dimensions: (" + simX + ", " + simY + ", " + simZ + ")");
                    write("Initial population: "+ initialPopulation);
                    write("Ratio " + populationRatio);
                    write("Spatial signalling diffusivity: " + diffusivity);
                    write("Spatial degradation (mu_e): " + mu_e);


                    if(fixedBounds){
                        write("Boundaries: fixed");
                    } else {
                        write("Boundaries: leaky");
                    }

                    write("Multiplier D_H: " + qsPars.get(0));
                    write("Multiplier D_I: " + qsPars.get(1));
                    write("Multiplier phi_H: " + qsPars.get(2));
                    write("Multiplier phi_I: " + qsPars.get(3));
                }

                @Override
                public void during() {

                }
            };
            metaLogger.setDt(10);//3600);			// Set export time step
            sim.addExporter(metaLogger);

            /*********************************************************
             * Log all Activator population grn values.
             */


            /*********************************************************
             * Logging the chemical fields: H.
             */
            BSimLogger chemicalFieldLogger_H = new BSimLogger(sim, filePath + "externalChemical_H.csv") {
                @Override
                public void during() {
                    write(sim.getFormattedTime());
                    String buffer = "";

                    int[] boxes = h_e_field.getBoxes();

                    for(int i = 0; i < boxes[0]; i++) {
                        buffer = "" + i;
                        for(int j = 0; j < boxes[1]; j++) {
                            buffer += "," + h_e_field.getConc(i, j, 0);
                        }
                        write(buffer);
                    }
                }
            };
            chemicalFieldLogger_H.setDt(10);
            sim.addExporter(chemicalFieldLogger_H);

            /*********************************************************
             * Logging the chemical fields: I.
             */
            BSimLogger chemicalFieldLogger_I = new BSimLogger(sim, filePath + "externalChemical_I.csv") {
                @Override
                public void during() {
                    write(sim.getFormattedTime());
                    String buffer = "";

                    int[] boxes = i_e_field.getBoxes();

                    for(int i = 0; i < boxes[0]; i++) {
                        buffer = "" + i;
                        for(int j = 0; j < boxes[1]; j++) {
                            buffer += "," + i_e_field.getConc(i, j, 0);
                        }
                        write(buffer);
                    }
                }
            };
            chemicalFieldLogger_I.setDt(10);
            sim.addExporter(chemicalFieldLogger_I);

            /*********************************************************
             * Position is fixed at the start; we log it once.
             */
//            BSimLogger posLogger = new BSimLogger(sim, filePath + "position.csv") {
//                DecimalFormat formatter = new DecimalFormat("###.##", DecimalFormatSymbols.getInstance( Locale.ENGLISH ));
//
//                @Override
//                public void before() {
//                    super.before();
//                    write("Initial cell positions. Fixed for the duration.");
//                    write("per Act; per Rep; id, p1x, p1y, p1z, p2x, p2y, p2z");
//                    String buffer = new String();
//
//                    write("Activators");
//
//                    buffer = "";
//                    for(BSimCapsuleBacterium b : bacteriaActivators) {
//                        buffer += b.id + "," + formatter.format(b.x1.x)
//                                + "," + formatter.format(b.x1.y)
//                                + "," + formatter.format(b.x1.z)
//                                + "," + formatter.format(b.x2.x)
//                                + "," + formatter.format(b.x2.y)
//                                + "," + formatter.format(b.x2.z)
//                                + "\n";
//                    }
//
//                    write(buffer);
//
//                    write("Repressors");
//
//                    buffer = "";
//                    for(BSimCapsuleBacterium b : bacteriaRepressors) {
//                        buffer += b.id + "," + formatter.format(b.x1.x)
//                                + "," + formatter.format(b.x1.y)
//                                + "," + formatter.format(b.x1.z)
//                                + "," + formatter.format(b.x2.x)
//                                + "," + formatter.format(b.x2.y)
//                                + "," + formatter.format(b.x2.z)
//                                + "\n";
//                    }
//
//                    write(buffer);
//                }
//
//                @Override
//                public void during() {
//
//                }
//            };
//            posLogger.setDt(30);			// Set export time step
//            sim.addExporter(posLogger);

            BSimLogger posLogger = new BSimLogger(sim, filePath + "position.csv") {
                DecimalFormat formatter = new DecimalFormat("###.##", DecimalFormatSymbols.getInstance( Locale.ENGLISH ));

                @Override
                public void before() {
                    super.before();
                    write("per Act; per Rep; id, p1x, p1y, p1z, p2x, p2y, p2z, growth_rate,directions");
                }

                @Override
                public void during() {
                    String buffer = new String();

                    buffer += sim.getFormattedTime() + "\n";
                    write(buffer);

                    write("acts");

                    buffer = "";
                    for(ChenBacterium b : bac0) {
                        buffer += b.id + "," + formatter.format(b.x1.x)
                                + "," + formatter.format(b.x1.y)
                                + "," + formatter.format(b.x1.z)
                                + "," + formatter.format(b.x2.x)
                                + "," + formatter.format(b.x2.y)
                                + "," + formatter.format(b.x2.z)
                                + "," + formatter.format(b.getK_growth())
                                + "\n";
                    }

                    write(buffer);

                    write("reps");

                    buffer = "";
                    for(ChenBacterium b : bac1) {
                        buffer += b.id + "," + formatter.format(b.x1.x)
                                + "," + formatter.format(b.x1.y)
                                + "," + formatter.format(b.x1.z)
                                + "," + formatter.format(b.x2.x)
                                + "," + formatter.format(b.x2.y)
                                + "," + formatter.format(b.x2.z)
                                + "," + formatter.format(b.getK_growth())
                                + "," + formatter.format(b.direction())
                                + "\n";
                    }

                    write(buffer);

                }
            };
            posLogger.setDt(10);			// Set export time step
            sim.addExporter(posLogger);


            BSimLogger sumLogger = new BSimLogger(sim, filePath + "summary.csv") {


                @Override
                public void before() {
                    super.before();
                    write("time,id, status, p1x, p1y, p1z, p2x, p2y, p2z, px, py, pz, growth_rate, directions");
                }

                @Override
                public void during() {
                    String buffer = new String();
                    buffer = "";
                    for(BSimCapsuleBacterium b : bacteriaAll) {
                        buffer += sim.getFormattedTime()+","+b.id
                                + "," + b.getInfected()
                                + "," + b.x1.x
                                + "," + b.x1.y
                                + "," + b.x1.z
                                + "," + b.x2.x
                                + "," + b.x2.y
                                + "," + b.x2.z
                                + "," + b.position.x
                                + "," + b.position.y
                                + "," + b.position.z
                                + "," + b.getK_growth()
                                + "," + b.direction()
                                + "\n";
                    }

                    write(buffer);
                }
            };
            sumLogger.setDt(10);			// Set export time step
            sim.addExporter(sumLogger);




            /**
             * Export a rendered image file
             */
            BSimPngExporter imageExporter = new BSimPngExporter(sim, drawer, filePath );
            imageExporter.setDt(5);
            sim.addExporter(imageExporter);

            sim.export();


            /**
             * Drawing a java plot once we're done?
             * See TwoCellsSplitGRNTest
             */

        } else {
            sim.preview();
        }

        long simulationEndTime = System.nanoTime();

        System.out.println("Total simulation time: " + (simulationEndTime - simulationStartTime)/1e9 + " sec.");
    }
}
